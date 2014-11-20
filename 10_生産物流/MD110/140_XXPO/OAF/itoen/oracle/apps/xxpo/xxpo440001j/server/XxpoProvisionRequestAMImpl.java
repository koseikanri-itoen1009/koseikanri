/*============================================================================
* ファイル名 : XxpoProvisionRequestAMImpl
* 概要説明   : 支給依頼要約アプリケーションモジュール
* バージョン : 1.18
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  二瓶大輔     新規作成
* 2008-06-06 1.0  二瓶大輔     内部変更要求#137対応
* 2008-06-17 1.1  二瓶大輔     ST不具合#126対応
* 2008-06-18 1.2  二瓶大輔     不具合対応
* 2008-06-02 1.3  二瓶大輔     変更要求#42対応
*                              ST不具合#199対応
* 2008-07-04 1.4  二瓶大輔     変更要求#91対応
* 2008-07-29 1.5  二瓶大輔     内部変更要求#164,166,173、課題#32
* 2008-08-13 1.6  二瓶大輔     ST不具合#249対応
* 2008-08-27 1.7  伊藤ひとみ   内部変更要求#209対応
* 2008-10-07 1.8  伊藤ひとみ   統合テスト指摘240対応
* 2008-10-21 1.9  二瓶大輔     T_S_437対応
*                              T_TE080_BPO_440 No14
* 2008-10-27 1.10 二瓶大輔     T_TE080_BPO_600 No22
* 2009-01-05 1.11 二瓶大輔     本番障害#861対応
* 2009-01-20 1.12 吉元強樹     本番障害#739,985対応(第1段階:金確ボタン)
* 2009-01-22 1.13 吉元強樹     本番障害#739,985対応(第2段階:ヘッダ・明細)
* 2009-02-03 1.14 二瓶大輔     本番障害#739,985対応(修正漏れ対応)
* 2009-02-13 1.15 伊藤ひとみ   本番障害#863,1184対応
* 2009-03-06 1.16 飯田  甫     本番障害#1131対応
* 2009-03-13 1.17 飯田  甫     本番障害#1300対応
* 2010-04-13 1.18 北寒寺 正夫  本稼動障害#2103対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.AttributeDef;
import oracle.jbo.RowSetIterator;
/***************************************************************************
 * 支給依頼要約画面のアプリケーションモジュールクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.17
 ***************************************************************************
 */
public class XxpoProvisionRequestAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRequestAMImpl()
  {
  }

  /***************************************************************************
   * 支給指示要約画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void initializeList(
    String exeType
    )
  {
    // 支給依頼要約検索VO
    XxpoProvSearchVOImpl vo = getXxpoProvSearchVO1();
    OARow row = null;
    // 1行もない場合、空行作成
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      row = (OARow)vo.first();
      row.setNewRowState(OARow.STATUS_INITIALIZED);
      row.setAttribute("RowKey",  new Number(1));
      row.setAttribute("ExeType", exeType);

      //プロファイルから代表価格表ID取得
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // 代表価格表が取得できない場合
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      row.setAttribute("RepPriceListId", repPriceListId);

    } else
    {
      row = (OARow)vo.first();
    }
    // 起動タイプが「12：パッカー･外注工場用」の場合
    if (XxpoConstants.EXE_TYPE_12.equals(exeType)
     && XxcmnUtility.isBlankOrNull(row.getAttribute("VendorId")))
    {
      // ユーザー情報取得 
      HashMap userInfo = XxpoUtility.getProvUserData(getOADBTransaction());
      // 仕入先に値を設定
      row.setAttribute("VendorId",     userInfo.get("VendorId"));
      row.setAttribute("VendorCode",   userInfo.get("VendorCode"));
      row.setAttribute("VendorName",   userInfo.get("VendorName"));

    }

    // 支給依頼要約PVO
    XxpoProvisionRequestPVOImpl pvo = getXxpoProvisionRequestPVO1();
    // 1行もない場合、空行作成
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      OARow prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
      // 起動タイプが「11：伊藤園用」の場合
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // 価格設定ボタン・受領ボタン・手動指示確定ボタン押下可
        prow.setAttribute("PriceSetBtnReject",   Boolean.FALSE); // 価格設定ボタン
        prow.setAttribute("RcvBtnReject",        Boolean.FALSE); // 受領ボタン
        prow.setAttribute("ManualFixBtnReject",  Boolean.FALSE); // 手動指示確定ボタン
      } else 
      {
        // 起動タイプが「12：パッカー･外注工場用」の場合
        if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
        {
          // 受領ボタン・手動指示確定ボタン押下不可  
          prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // 受領ボタン
          prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // 手動指示確定ボタン
          prow.setAttribute("CopyBtnReject",       Boolean.TRUE); // コピーボタン
          
        } else
        {
          // 受領ボタン・手動指示確定ボタン押下可能  
          prow.setAttribute("RcvBtnReject",        Boolean.FALSE); // 受領ボタン
          prow.setAttribute("ManualFixBtnReject",  Boolean.FALSE); // 手動指示確定ボタン

        }
        // 価格設定ボタン押下不可
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン
        // 金額確定ボタン押下不可
        prow.setAttribute("AmountFixBtnReject", Boolean.TRUE); // 金額確定ボタン

      }
    }
  } // initializeList

  /***************************************************************************
   * 支給指示要約画面の検索処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchList() throws OAException
  {
    // 支給指示検索VO取得
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();

    // 検索条件設定
    OARow shRow = (OARow)svo.first();
    HashMap shParams = new HashMap();
    shParams.put("orderType",    shRow.getAttribute("OrderType"));       // 発生区分
    shParams.put("vendorCode",   shRow.getAttribute("VendorCode"));      // 取引先
    shParams.put("shipToCode",   shRow.getAttribute("ShipToCode"));      // 配送先
    shParams.put("reqNo",        shRow.getAttribute("ReqNo"));           // 依頼No
    shParams.put("shipToNo",     shRow.getAttribute("ShipToNo"));        // 配送No
    shParams.put("transStatus",  shRow.getAttribute("TransStatusCode")); // ステータス
    shParams.put("notifStatus",  shRow.getAttribute("NotifStatusCode")); // 通知ステータス
    shParams.put("shipDateFrom", shRow.getAttribute("ShipDateFrom"));    // 出庫日From
    shParams.put("shipDateTo",   shRow.getAttribute("ShipDateTo"));      // 出庫日To
    shParams.put("arvlDateFrom", shRow.getAttribute("ArvlDateFrom"));    // 入庫日From
    shParams.put("arvlDateTo",   shRow.getAttribute("ArvlDateTo"));      // 入庫日To
    shParams.put("reqDeptCode",  shRow.getAttribute("ReqDeptCode"));     // 依頼部署
    shParams.put("instDeptCode", shRow.getAttribute("InstDeptCode"));    // 指示部署
    shParams.put("shipWhseCode", shRow.getAttribute("ShipWhseCode"));    // 出庫倉庫
    shParams.put("exeType",      shRow.getAttribute("ExeType"));         // 起動タイプ
    shParams.put("baseReqNo",    shRow.getAttribute("BaseReqNo"));       // 元依頼No
// 2009-03-13 H.Iida ADD START 本番障害#1300
    shParams.put("fixClass",     shRow.getAttribute("FixClass"));        // 金額確定
// 2009-03-13 H.Iida ADD END

    // 支給指示結果VO取得
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 検索を実行します。
    vo.initQuery(shParams);

  } // doSearchList

  /***************************************************************************
   * 支給指示要約画面の確定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doFixList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示結果VO取得
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 選択されたレコードを取得
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 確定処理チェック
      chkFix(vo, row, exceptions);

    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 排他チェック
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      // ステータスを「入力完了」に更新します。
      XxpoUtility.updateTransStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.PROV_STATUS_NRK);
      exeFlag = true;
    }
    // 実行された場合
    if (exeFlag) 
    {
      // コミット発行
      doCommitList();
      // 確定処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_FIX);
    }
  } // doFixList

  /***************************************************************************
   * ページングの際にチェックボックスをOFFにします。
   ***************************************************************************
   */
  public void checkBoxOff()
  {
    // 処理対象を取得します。
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // チェックボックスをOFFにします。
    if ((rows != null) || (rows.length != 0)) 
    {
      OARow row = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i番目の行を取得
        row = (OARow)rows[i];
        row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * 未選択チェックを行うメソッドです。
   * @param rows - 行オブジェクト配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkNonChoice(
    Row[] rows
    ) throws OAException
  {
    // 未選択チェックを行います。
    if ((rows == null) || (rows.length == 0)) 
    {
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10144);
    }
  } // chkNonChoice

  /***************************************************************************
   * 支給指示要約画面の受領処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doRcvList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示結果VO取得
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 選択されたレコードを取得
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 受領処理チェック
      chkRcv(vo, row, exceptions);

    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 排他チェック
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      // ステータスを「受領済」に更新します。
      XxpoUtility.updateTransStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.PROV_STATUS_ZRZ);
      String autoCreatePoClass = (String)row.getAttribute("AutoCreatePoClass"); // 自動発注作成区分
      // 自動発注作成区分が「対象」の場合
      if ("1".equals(autoCreatePoClass)) 
      {
        String reqNo = (String)row.getAttribute("RequestNo"); // 依頼No
        // 自動発注作成を実行
        XxpoUtility.provAutoPurchaseOrders(getOADBTransaction(), reqNo);
// 2009-01-05 D.Nihei Del Start
//        // 通知ステータスを「確定通知済」に更新します。
//        XxpoUtility.updateNotifStatus(
//          getOADBTransaction(),
//          orderHeaderId,
//          XxpoConstants.NOTIF_STATUS_KTZ);
// 2009-01-05 D.Nihei Del End

      }
      exeFlag = true;
    }
    // 実行された場合
    if (exeFlag) 
    {
      // コミット発行
      doCommitList();
      // 受領処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_RCV);

    }
  } // doRcvList

  /***************************************************************************
   * 支給指示要約画面の手動指示確定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doManualFixList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示結果VO取得
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 選択されたレコードを取得
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 手動指示確定処理チェック
      chkManualFix(vo, row, exceptions, true);
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 排他チェック
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      // 通知ステータスを「確定通知済」に更新します。
      XxpoUtility.updateNotifStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.NOTIF_STATUS_KTZ);
      exeFlag = true;
    }
    // 実行された場合
    if (exeFlag) 
    {
      // コミット発行
      doCommitList();
      // 手動指示確定処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_MANUAL_FIX);

    }
  } // doManualFixList

  /***************************************************************************
   * 支給指示要約画面の価格設定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doPriceSetList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示結果VO取得
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 選択されたレコードを取得
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 価格設定処理チェック
      chkPriceSet(vo, row, exceptions, true);
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    //支給指示要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    // 代表価格表取得
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId");          
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 排他チェック
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      // 価格設定処理を実行します。
      String listIdVendor = (String)row.getAttribute("ListHeaderIdVendor"); // 取引先価格表ID
      Date arrivalDate    = (Date)row.getAttribute("ArrivalDate");          // 入庫日
      //単価更新処理実行
      String errItemNo = XxpoUtility.updateUnitPrice(
                           getOADBTransaction(),
                           orderHeaderId,
                           listIdVendor,
                           listIdRepresent,
                           arrivalDate,
                           null,
                           null,
                           null
                         );
      // エラー品目Noが入っていた場合
      if (!XxcmnUtility.isBlankOrNull(errItemNo)) 
      {
        Number orderType = (Number)row.getAttribute("OrderTypeId"); // 発生区分
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_ITEM,
                                                   errItemNo) };
        // 価格設定エラー
        throw new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    vo.getName(),
                    row.getKey(),
                    "OrderTypeId",
                    orderType,
                    XxcmnConstants.APPL_XXPO,
                    XxpoConstants.XXPO10200,
                    tokens);
            
      }
      exeFlag = true;
    }
    // 実行された場合
    if (exeFlag) 
    {
      // コミット発行
      doCommitList();
      // 価格設定処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_PRICE_SET);
    }
  } // doPriceSetList

  /***************************************************************************
   * 支給指示要約画面の金額確定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doAmountFixList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示結果VO取得
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 選択されたレコードを取得
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 有償金額確定処理チェック
      chkAmountFix(vo, row, exceptions);
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // 排他チェック
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID

// 2009-01-20 v1.12 T.Yoshimoto Add Start 本番#985
      Date updateArrivalDate = getUpdateArrivalDate(row);

      XxpoUtility.updArrivalDate(
        getOADBTransaction(),
        orderHeaderId,
        updateArrivalDate);
// 2009-01-20 v1.12 T.Yoshimoto Add End 本番#985

      // 有償金額確定処理を実行します。
      XxpoUtility.updateFixClass(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.FIX_CLASS_ON);
      exeFlag = true;
    }
    // 実行された場合
    if (exeFlag) 
    {
      // コミット発行
      doCommitList();
      // 金額確定処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_AMOUNT_FIX);
    }
  } // doAmountFixList

  /***************************************************************************
   * 支給指示要約画面のコミット・再検索処理を行うメソッドです。
   ***************************************************************************
   */
  public void doCommitList()
  {
    // コミット発行
    XxpoUtility.commit(getOADBTransaction());
    // 再検索を行います。
    doSearchList();

  } // doCommitList

  /***************************************************************************
   * 支給指示作成ヘッダ画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param reqNo   - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    ) throws OAException
  {
    // 支給依頼要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0)
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey",  new Number(1));
      srow.setAttribute("ExeType", exeType);
      //プロファイルから代表価格表ID取得
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // 代表価格表が取得できない場合
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      srow.setAttribute("RepPriceListId", repPriceListId);
    }
    // 支給指示作成ヘッダPVO
    XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
    // 1行もない場合、空行作成
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));

    } else
    {
      prow = (OARow)pvo.first();
      // 初期化
      handleEventAllOnHdr(prow);

    }

    OARow row  = null;
    // 新規の場合
    if (XxcmnUtility.isBlankOrNull(reqNo)) 
    {
      // 支給指示作成ヘッダVO取得
      XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
      if (vo.getFetchedRowCount() == 0)
      {
        vo.setMaxFetchSize(0);
        vo.executeQuery();
        vo.insertRow(vo.createRow());
        row = (OARow)vo.first();
        row.setNewRowState(OARow.STATUS_INITIALIZED);
      } else
      {
        row = (OARow)vo.first();
      }
      // キーの設定
      row.setAttribute("OrderHeaderId", new Number(-1));
      // デフォルト値の設定
      row.setAttribute("NewFlag",             XxcmnConstants.STRING_Y);              // 新規フラグ
      row.setAttribute("TransStatus",         XxpoConstants.PROV_STATUS_NRT);        // ステータス
      row.setAttribute("NotifStatus",         XxpoConstants.NOTIF_STATUS_MTT);       // 通知ステータス
      row.setAttribute("WeightCapacityClass", XxpoConstants.WGHT_CAPA_CLASS_WEIGHT); // 重量容積区分
      row.setAttribute("RcvClass",            XxpoConstants.RCV_CLASS_OFF);          // 指示受領
      row.setAttribute("FixClass",            XxpoConstants.FIX_CLASS_OFF);          // 金額確定

      // 起動タイプが「15：資材メーカー用」の場合
      if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // 対象外に設定
        row.setAttribute("FreightChargeClass",  XxcmnConstants.OBJECT_OFF); // 運賃区分

      // 上記以外
      } else 
      {
        // 対象に設定
        row.setAttribute("FreightChargeClass",  XxcmnConstants.OBJECT_ON); // 運賃区分

      }
        
      // 起動タイプが「12：パッカー･外注工場用」の場合
      if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // ユーザー情報取得 
        HashMap userInfo = XxpoUtility.getProvUserData(getOADBTransaction());
        // 仕入先・顧客に値を設定
        row.setAttribute("VendorId",     userInfo.get("VendorId"));
        row.setAttribute("VendorCode",   userInfo.get("VendorCode"));
        row.setAttribute("VendorName",   userInfo.get("VendorName"));
        row.setAttribute("CustomerId",   userInfo.get("CustomerId"));
        row.setAttribute("CustomerCode", userInfo.get("CustomerCode"));
        row.setAttribute("PriceList",    userInfo.get("PriceList"));

      }

      // 新規時項目制御
      handleEventInsHdr(exeType, prow, row);

    // 更新の場合
    } else 
    {
      // 依頼Noで検索を実行
      doSearchHdr(reqNo);

      // 支給指示作成ヘッダVO取得
      XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
      row = (OARow)vo.first();

      // 更新時項目制御
      handleEventUpdHdr(exeType, prow, row);

    }

    // 明細行の検索
    doSearchLine(exeType);

  } // initializeHdr
  
  /***************************************************************************
   * 支給指示作成ヘッダ画面の新規時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param prow    - PVO行クラス
   * @param row     - VO行クラス
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void handleEventInsHdr(
    String exeType,
    OARow prow,
    OARow row
    ) throws OAException
  {
    // 共通ボタン制御
    prow.setAttribute("FixBtnReject",        Boolean.TRUE); // 確定ボタン
    prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // 受領ボタン
    prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // 手動指示確定ボタン
    prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン
    prow.setAttribute("PriceSetBtnReject",   Boolean.TRUE); // 価格設定ボタン
    // 共通項目制御
    prow.setAttribute("FixReadOnly", Boolean.TRUE); // 金額確定

    // 起動タイプが「11：伊藤園用」の場合
    if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
    {
      // なし

    // 起動タイプが「12：パッカー･外注工場用」の場合
    } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
    {
      // 項目制御
      prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
      prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者

    // 起動タイプが「13：東洋埠頭用」の場合
    } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
    {
      // なし

    // 起動タイプが「15：資材メーカー用」の場合
    } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
    {
      // 項目制御
      prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者
      prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

    }
  } // handleEventInsHdr

  /***************************************************************************
   * 支給指示作成ヘッダ画面の更新時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param prow    - PVO行クラス
   * @param row     - VO行クラス
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void handleEventUpdHdr(
    String exeType,
    OARow prow,
    OARow row
    ) throws OAException
  {
    // 初期化
    handleEventAllOnHdr(prow);
    // ステータスを取得
    String transStatus = (String)row.getAttribute("TransStatus");
    // ステータス共通項目制御
    prow.setAttribute("WeightCapacityReadOnly" , Boolean.TRUE);                  // 重量容積区分
    prow.setAttribute("InstDeptRequired"       , XxcmnConstants.STRING_UI_ONLY); // 指示部署
    prow.setAttribute("ShippedDateRequired"    , XxcmnConstants.STRING_UI_ONLY); // 出庫日

    String freightChargeClass = (String)row.getAttribute("FreightChargeClass"); // 運賃区分
    if (XxcmnConstants.OBJECT_ON.equals(freightChargeClass)) 
    {
      prow.setAttribute("FreightCarrierRequired" , XxcmnConstants.STRING_UI_ONLY); // 運送業者
    }

    // ステータスが「入力中」の場合 
    if (XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      // 共通ボタン制御
      prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // 受領ボタン
      prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // 手動指示確定ボタン

      // 共通項目制御
      prow.setAttribute("FixReadOnly",            Boolean.TRUE); // 金額確定

      // 起動タイプが「11：伊藤園用」の場合
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // なし

      // 起動タイプが「12：パッカー･外注工場用」の場合
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン
        // 項目制御
        prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者

      // 起動タイプが「13：東洋埠頭用」の場合
      } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン

      // 起動タイプが「15：資材メーカー用」の場合
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者
        prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

      }

    // ステータスが「入力完了」の場合 
    } else if (XxpoConstants.PROV_STATUS_NRK.equals(transStatus))
    {
      // 共通ボタン制御
      prow.setAttribute("FixBtnReject",        Boolean.TRUE); // 確定ボタン
      prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // 手動指示確定ボタン

      // 共通項目制御
      prow.setAttribute("FixReadOnly",            Boolean.TRUE); // 金額確定

      // 起動タイプが「11：伊藤園用」の場合
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // なし

      // 起動タイプが「12：パッカー･外注工場用」の場合
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("RcvBtnReject",      Boolean.TRUE); // 受領ボタン
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン
        // 項目制御
        prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者

      // 起動タイプが「13：東洋埠頭用」の場合
      } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン

      // 起動タイプが「15：資材メーカー用」の場合
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン
        // 項目制御
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者
        prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

      }
    
    // ステータスが「受領済」の場合 
    } else if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // 受領タイプ取得
      String rcvType = (String)row.getAttribute("RcvType");
      // 共通ボタン制御
      prow.setAttribute("FixBtnReject",        Boolean.TRUE); // 確定ボタン
      prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // 受領ボタン
      // 共通項目制御
      prow.setAttribute("OrderTypeReadOnly",  Boolean.TRUE); // 発生区分
      prow.setAttribute("FixReadOnly",        Boolean.TRUE); // 金額確定

      // 通知ステータを取得します。
      String notifStatus = (String)row.getAttribute("NotifStatus");    // 通知ステータス
      // 通知ステータスが「確定通知済」の場合
      if (XxpoConstants.NOTIF_STATUS_KTZ.equals(notifStatus))
      {
        // ボタン制御
        prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // 手動指示確定ボタン
      }

      // 起動タイプが「11：伊藤園用」の場合
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {

        // 受領タイプが「5：一部実績有」の場合
        if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // 依頼部署
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // 配送先
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // 入庫日
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分
          
        // 受領タイプが「4：配車済・引当有」の場合
        } else if (XxpoConstants.RCV_TYPE_4.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // 依頼部署
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分
          
        // 受領タイプが「3：配車済・未引当」の場合
        } else if (XxpoConstants.RCV_TYPE_3.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // 依頼部署
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

        // 受領タイプが「2：引当有」の場合
        } else if (XxpoConstants.RCV_TYPE_2.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日

        // 受領タイプが「1：発注済」の場合
        } else if (XxpoConstants.RCV_TYPE_1.equals(rcvType))
        {
          // 項目制御
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // 配送先
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // 入庫日

        // 受領タイプが「0：未発注」の場合
        } else if (XxpoConstants.RCV_TYPE_0.equals(rcvType))
        {
          // なし
        } else
        {
          // 想定外のため参照のみ
          handleEventAllOffHdr(prow);
// 2008-08-27 H.Itou Add Start 内部変更要求#209 出荷実績計上済の場合など、明細画面へ遷移できなくなるので、
//   handleEventAllOffHdr内で次へボタン制御をしないで下さい。
          prow.setAttribute("NextBtnReject", Boolean.TRUE); // 次へボタン
// 2008-08-27 H.Itou Add End
        }

      // 起動タイプが「12：パッカー･外注工場用」の場合
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // 参照のみ
        handleEventAllOffHdr(prow);

      // 起動タイプが「13：東洋埠頭用」の場合
      } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // 価格設定ボタン
        // 項目制御
        prow.setAttribute("ReqDeptReadOnly", Boolean.TRUE); // 依頼部署

        // 受領タイプが「5：一部実績有」の場合
        if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // 配送先
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // 入庫日
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分
          
        // 受領タイプが「4：配車済・引当有」の場合
        } else if (XxpoConstants.RCV_TYPE_4.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

        // 受領タイプが「3：配車済・未引当」の場合
        } else if (XxpoConstants.RCV_TYPE_3.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

        // 受領タイプが「2：引当有」の場合
        } else if (XxpoConstants.RCV_TYPE_2.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
        }
      // 起動タイプが「15：資材メーカー用」の場合
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // ボタン制御
        prow.setAttribute("PriceSetBtnReject",      Boolean.TRUE); // 価格設定ボタン
        // 項目制御
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // 運送業者
        prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // 運賃区分

        // 受領タイプが「5：一部実績有」の場合
        if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // 依頼部署
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // 配送先
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // 入庫日
          
        // 受領タイプが「2：引当有」の場合
        } else if (XxpoConstants.RCV_TYPE_2.equals(rcvType))
        {
          // ボタン制御
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // 支給取消ボタン
          // 項目制御
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // 依頼部署
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日

        // 受領タイプが「1：発注済」の場合
        } else if (XxpoConstants.RCV_TYPE_1.equals(rcvType))
        {
          // 項目制御
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // 依頼部署
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // 配送先
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // 出庫倉庫
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // 出庫日
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // 入庫日

        // 受領タイプが「0：未発注」の場合
        } else if (XxpoConstants.RCV_TYPE_0.equals(rcvType))
        {
          // 項目制御
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // 取引先

        } else
        {
          // 想定外のため参照のみ
          handleEventAllOffHdr(prow);
// 2008-08-27 H.Itou Add Start 内部変更要求#209 出荷実績計上済の場合など、明細画面へ遷移できなくなるので、
//   handleEventAllOffHdr内で次へボタン制御をしないで下さい。
          prow.setAttribute("NextBtnReject", Boolean.TRUE); // 次へボタン
// 2008-08-27 H.Itou Add End

        }
      }
    // ステータスが「出荷実績計上済」の場合 
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus))
    {
      // 参照のみ
      handleEventAllOffHdr(prow);

      // 起動タイプが「11：伊藤園用」の場合
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // 項目制御
        prow.setAttribute("FixReadOnly", Boolean.FALSE); // 金額確定

        // 金額確定フラグを取得
        String fixClass = (String)row.getAttribute("FixClass"); 
        // 金額未確定
        if (XxpoConstants.FIX_CLASS_OFF.equals(fixClass)) 
        {
          // ボタン制御
          prow.setAttribute("PriceSetBtnReject", Boolean.FALSE); // 価格設定ボタン
          // 項目制御
          prow.setAttribute("InstDeptReadOnly",  Boolean.FALSE); // 指示部署
            
        }
      }
    }
  } // handleEventUpdHdr

  /***************************************************************************
   * 支給指示作成ヘッダ画面の項目を全てTRUEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOffHdr(OARow prow)
  {
// 出荷実績計上済の場合など、明細画面へ遷移できなくなるので、
//   handleEventAllOffHdr内で次へボタン制御をしないで下さい。
    prow.setAttribute("FixBtnReject"                 , Boolean.TRUE); // 確定ボタン
    prow.setAttribute("RcvBtnReject"                 , Boolean.TRUE); // 受領ボタン
    prow.setAttribute("ManualFixBtnReject"           , Boolean.TRUE); // 手動指示確定ボタン
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.TRUE); // 支給取消ボタン
    prow.setAttribute("PriceSetBtnReject"            , Boolean.TRUE); // 価格設定ボタン
    prow.setAttribute("OrderTypeReadOnly"            , Boolean.TRUE); // 発生区分
    prow.setAttribute("WeightCapacityReadOnly"       , Boolean.TRUE); // 重量容積区分
    prow.setAttribute("ReqDeptReadOnly"              , Boolean.TRUE); // 依頼部署
    prow.setAttribute("VendorReadOnly"               , Boolean.TRUE); // 取引先
    prow.setAttribute("ShipToReadOnly"               , Boolean.TRUE); // 配送先
    prow.setAttribute("ShipWhseReadOnly"             , Boolean.TRUE); // 出庫倉庫
    prow.setAttribute("FreightCarrierReadOnly"       , Boolean.TRUE); // 運送業者
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.TRUE); // 出庫日
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.TRUE); // 入庫日
    prow.setAttribute("ArrivalTimeFromReadOnly"      , Boolean.TRUE); // 着荷時間From
    prow.setAttribute("ArrivalTimeToReadOnly"        , Boolean.TRUE); // 着荷時間To
    prow.setAttribute("FreightChargeReadOnly"        , Boolean.TRUE); // 運賃区分
    prow.setAttribute("TakebackReadOnly"             , Boolean.TRUE); // 引取区分
    prow.setAttribute("DesignatedProdDateReadOnly"   , Boolean.TRUE); // 製造日
    prow.setAttribute("DesignatedItemReadOnly"       , Boolean.TRUE); // 製造品目
    prow.setAttribute("DesignatedBranchNoReadOnly"   , Boolean.TRUE); // 製造番号
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.TRUE); // 摘要
    prow.setAttribute("FixReadOnly"                  , Boolean.TRUE); // 金額確定
    prow.setAttribute("InstDeptReadOnly"             , Boolean.TRUE); // 指示部署

  } // handleEventAllOffHdr

  /***************************************************************************
   * 支給指示作成ヘッダ画面の項目を全てFALSEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOnHdr(OARow prow)
  {
    prow.setAttribute("FixBtnReject"                 , Boolean.FALSE); // 確定ボタン
    prow.setAttribute("RcvBtnReject"                 , Boolean.FALSE); // 受領ボタン
    prow.setAttribute("ManualFixBtnReject"           , Boolean.FALSE); // 手動指示確定ボタン
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.FALSE); // 支給取消ボタン
    prow.setAttribute("PriceSetBtnReject"            , Boolean.FALSE); // 価格設定ボタン
    prow.setAttribute("OrderTypeReadOnly"            , Boolean.FALSE); // 発生区分
    prow.setAttribute("WeightCapacityReadOnly"       , Boolean.FALSE); // 重量容積区分
    prow.setAttribute("ReqDeptReadOnly"              , Boolean.FALSE); // 依頼部署
    prow.setAttribute("VendorReadOnly"               , Boolean.FALSE); // 取引先
    prow.setAttribute("ShipToReadOnly"               , Boolean.FALSE); // 配送先
    prow.setAttribute("ShipWhseReadOnly"             , Boolean.FALSE); // 出庫倉庫
    prow.setAttribute("FreightCarrierReadOnly"       , Boolean.FALSE); // 運送業者
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.FALSE); // 出庫日
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.FALSE); // 入庫日
    prow.setAttribute("ArrivalTimeFromReadOnly"      , Boolean.FALSE); // 着荷時間From
    prow.setAttribute("ArrivalTimeToReadOnly"        , Boolean.FALSE); // 着荷時間To
    prow.setAttribute("FreightChargeReadOnly"        , Boolean.FALSE); // 運賃区分
    prow.setAttribute("TakebackReadOnly"             , Boolean.FALSE); // 引取区分
    prow.setAttribute("DesignatedProdDateReadOnly"   , Boolean.FALSE); // 製造日
    prow.setAttribute("DesignatedItemReadOnly"       , Boolean.FALSE); // 製造品目
    prow.setAttribute("DesignatedBranchNoReadOnly"   , Boolean.FALSE); // 製造番号
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.FALSE); // 摘要
    prow.setAttribute("FixReadOnly"                  , Boolean.FALSE); // 金額確定
    prow.setAttribute("InstDeptReadOnly"             , Boolean.FALSE); // 指示部署
    prow.setAttribute("InstDeptRequired"             , XxcmnConstants.STRING_NO); // 指示部署
    prow.setAttribute("FreightCarrierRequired"       , XxcmnConstants.STRING_NO); // 運送業者
    prow.setAttribute("ShippedDateRequired"          , XxcmnConstants.STRING_NO); // 出庫日

  } // handleEventAllOnHdr

  /***************************************************************************
   * 支給指示作成ヘッダ画面の検索処理を行うメソッドです。
   * @param  reqNo - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchHdr(
    String reqNo
    ) throws OAException
  {
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    // 検索を実行します。
    vo.initQuery(reqNo);
    vo.first();
    // 対象データを取得できない場合エラー
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // 支給指示作成PVO
      XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // 参照のみ
      handleEventAllOffHdr(prow);
// 2008-08-27 H.Itou Add Start 内部変更要求#209 出荷実績計上済の場合など、明細画面へ遷移できなくなるので、
//   handleEventAllOffHdr内で次へボタン制御をしないで下さい。
      prow.setAttribute("NextBtnReject", Boolean.TRUE); // 次へボタン
// 2008-08-27 H.Itou Add End
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);

    }
  } // doSearchHdr

  /***************************************************************************
   * 支給指示作成ヘッダ画面の確定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doFix() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 確定処理チェック
    chkFix(vo, row, exceptions);
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // 排他チェック
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    String requestNo     = (String)row.getAttribute("RequestNo");     // 依頼No
    // ステータスを「入力完了」に更新します。
    XxpoUtility.updateTransStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.PROV_STATUS_NRK);

    // コミット発行
    doCommit(requestNo);
    // 確定処理成功メッセージを表示
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_FIX);

  } // doFix

  /***************************************************************************
   * 支給指示作成ヘッダ画面の受領処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doRcv() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 受領処理チェック
    chkRcv(vo, row, exceptions);
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // 排他チェック
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    String requestNo     = (String)row.getAttribute("RequestNo");     // 依頼No
    // ステータスを「受領済」に更新します。
    XxpoUtility.updateTransStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.PROV_STATUS_ZRZ);
    String autoCreatePoClass = (String)row.getAttribute("AutoCreatePoClass"); // 自動発注作成区分
    // 自動発注作成区分が「対象」の場合
    if ("1".equals(autoCreatePoClass)) 
    {
      // 自動発注作成を実行
      String reqNo = (String)row.getAttribute("RequestNo"); // 依頼No
      // 自動発注作成を実行
      XxpoUtility.provAutoPurchaseOrders(getOADBTransaction(), reqNo);
// 2009-01-05 D.Nihei Del Start
//      // 通知ステータスを「確定通知済」に更新します。
//      XxpoUtility.updateNotifStatus(
//        getOADBTransaction(),
//        orderHeaderId,
//        XxpoConstants.NOTIF_STATUS_KTZ);
// 2009-01-05 D.Nihei Del End

    }

    // コミット発行
    doCommit(requestNo);
    // 受領処理成功メッセージを表示
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_RCV);

  } // doRcv

  /***************************************************************************
   * 支給指示作成ヘッダ画面の手動指示確定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doManualFix() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 手動指示確定チェック
    chkManualFix(vo, row, exceptions, false);
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    // 排他チェック
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    String requestNo     = (String)row.getAttribute("RequestNo");     // 依頼No
    // 通知ステータスを「確定通知済」に更新します。
    XxpoUtility.updateNotifStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.NOTIF_STATUS_KTZ);

    // コミット発行
    doCommit(requestNo);
    // 手動指示確定成功メッセージを表示
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_MANUAL_FIX);
  } // doManualFix

  /***************************************************************************
   * 支給指示作成ヘッダ画面の価格設定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doPriceSet() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 価格設定処理チェック
    chkPriceSet(vo, row, exceptions, false);
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // 排他チェック
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    String requestNo     = (String)row.getAttribute("RequestNo");     // 依頼No
    String listIdVendor  = (String)row.getAttribute("PriceList");     // 取引先価格表ID
    Date arrivalDate     = (Date)row.getAttribute("ArrivalDate");     // 入庫日
    //支給指示要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId"); // 代表価格表取得
    // 価格設定処理を実行します。
    String errItemNo = XxpoUtility.updateUnitPrice(
                         getOADBTransaction(),
                         orderHeaderId,
                         listIdVendor,
                         listIdRepresent,
                         arrivalDate,
                         null,
                         null,
                         null
                       );
    // エラー品目Noが入っていた場合
    if (!XxcmnUtility.isBlankOrNull(errItemNo)) 
    {
      Number orderType = (Number)row.getAttribute("OrderTypeId"); // 発生区分
      //トークンを生成します。
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_ITEM,
                                                 errItemNo) };
      // 価格設定エラー
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "OrderTypeId",
                  orderType,
                  XxcmnConstants.APPL_XXPO,
                  XxpoConstants.XXPO10200,
                  tokens);
            
    }

    // コミット発行
    doCommit(requestNo);
    // 価格設定処理成功メッセージを表示
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_PRICE_SET);

  } // doPriceSet

  /***************************************************************************
   * 支給指示作成ヘッダ画面の支給取消処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doProvCancel() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 排他チェック
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    String requestNo     = (String)row.getAttribute("RequestNo");     // 依頼No
    // ステータスを取得
    String transStatus = (String)row.getAttribute("TransStatus");
    // ステータスが「受領済」の場合 
    if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // 配車解除処理実行
      String retCode = XxwshUtility.cancelCareersSchedile(getOADBTransaction(),
                                                          XxcmnConstants.BIZ_TYPE_PROV,
                                                          requestNo);
      // パラメータチェックエラーの場合
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // 予期せぬエラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // 配車処理失敗の場合
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAREERS);

      }
    }
    // ステータスを「取消」に更新します。
    XxpoUtility.updateTransStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.PROV_STATUS_CAN);

    // コミット発行
    XxpoUtility.commit(getOADBTransaction());

  } // doProvCancel

  /***************************************************************************
   * 支給指示作成ヘッダ画面の次へ処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doNext() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 次へ処理チェック
    chkNext(vo, row, exceptions);

    // 導出処理
    getHdrData(vo, row);

    // 変更に関する警告処理
    doWarnAboutChanges();
  } // doNext

  /***************************************************************************
   * 支給指示作成明細画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void initializeLine(String exeType)
  {
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVvo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVvo.first();

    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // 新規フラグ
    // 支給指示作成明細PVO
    XxpoProvisionInstMakeLinePVOImpl pvo = getXxpoProvisionInstMakeLinePVO1();
    // 1行もない場合、空行作成
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
      // PVO初期値設定
      handleEventAllOnLine(prow);

    } else
    {
      prow = (OARow)pvo.first();

    }
    // 新規フラグが「N：更新」の場合
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      handleEventUpdLine(exeType,
                         prow,
                         hdrRow);      

    // 新規の場合
    } else 
    {
      handleEventInsLine(exeType,
                         prow);      
      
    }
  } // initializeLine
  
  /*****************************************************************************
   * 指定された行を削除します。
   * @param exeType - 起動タイプ
   * @param orderLineNumber - 明細番号
   * @throws OAException - OA例外
   ****************************************************************************/
  public void doDeleteLine(
    String exeType,
    String orderLineNumber
    ) throws OAException 
  {
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow   = (OARow)hdrVo.first();
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // 依頼No
    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // 新規フラグ

    // 支給指示作成明細VO
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // 削除対象行を取得
    OARow row = (OARow)vo.getFirstFilteredRow("OrderLineNumber", new Number(Integer.parseInt(orderLineNumber)));
    Number orderLineId = (Number)row.getAttribute("OrderLineId"); // 受注明細アドオンID

    // 全行取得
    Row[] rows = vo.getAllRowsInRange();
    // 取得行の明細件数が1件しかない場合
    if ((rows == null) || (rows.length == 1)) 
    {
      Object itemNo = row.getAttribute("ItemNo");
      // 削除不可エラー
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "ItemNo",
                  itemNo,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10152);

    }
    
    // 挿入行の場合
    if (XxcmnUtility.isBlankOrNull(orderLineId))
    {
      // 挿入行削除
      row.remove();

// 2008-10-21 D.Nihei DEL START
//      // コミット処理
//      doCommit(reqNo);
// 2008-10-21 D.Nihei DEL END

      // 削除処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);

    // 更新行の場合
    } else
    {
      // 削除チェック処理
      chkOrderLineDel(vo, hdrRow, row);

      // 排他チェック
      chkLockAndExclusive(hdrVo, hdrRow);

      // 削除処理
      XxpoUtility.deleteOrderLine(getOADBTransaction(), orderLineId);

      // 配車関連情報設定
      setCarriersData(hdrRow);

      // 各種情報取得
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      String sumQuantity   = (String)hdrRow.getAttribute("SumQuantity");   // 合計数量
      Number smallQuantity = (Number)hdrRow.getAttribute("SmallQuantity"); // 小口個数
      Number labelQuantity = (Number)hdrRow.getAttribute("LabelQuantity"); // ラベル枚数
      String sumWeight     = (String)hdrRow.getAttribute("SumWeight");     // 積載重量合計
      String sumCapacity   = (String)hdrRow.getAttribute("SumCapacity");   // 積載容積合計
// 2009-02-13 H.Itou Add Add Start 本番障害#863対応 配車解除されない場合もあるので積載効率を再計算。
      String shipToCode         = (String)hdrRow.getAttribute("ShipToCode");          // 配送先
      String shipWhseCode       = (String)hdrRow.getAttribute("ShipWhseCode");        // 出庫倉庫
      String shippingMethodCode = (String)hdrRow.getAttribute("ShippingMethodCode");  // 配送区分
      Date   shippedDate        = (Date)hdrRow.getAttribute("ShippedDate");           // 出庫日
      String freightChargeClass = (String)hdrRow.getAttribute("FreightChargeClass");  // 運賃区分
      String loadEfficiencyWeight = null;
      String loadEfficiencyCapacity = null;

      // 運賃区分が「対象」の場合、積載効率再計算
      if (XxcmnConstants.OBJECT_ON.equals(freightChargeClass))
      {
        /******************
         * 重量積載効率算出(積載オーバーでもエラーとならないXxwshUtilityの関数を使用)
         ******************/
        HashMap params3 = XxwshUtility.calcLoadEfficiency(
                           getOADBTransaction(),
                           sumWeight,
                           null,
                           "4",  // 倉庫
                           shipWhseCode,
                           "11", // 支給先
                           shipToCode,
                           shippingMethodCode, // 設定した配送区分,
                           shippedDate,
                           XxcmnUtility.getProfileValue(getOADBTransaction(), "XXCMN_ITEM_DIV_SECURITY"));
        /******************
         * 重量積載効率をセット
         ******************/
        loadEfficiencyWeight = (String)params3.get("loadEfficiencyWeight");   // 重量積載効率

        /******************
         * 容積積載効率算出(積載オーバーでもエラーとならないXxwshUtilityの関数を使用)
         ******************/
        HashMap params4 = XxwshUtility.calcLoadEfficiency(
                           getOADBTransaction(),
                           null,
                           sumCapacity,
                           "4",  // 倉庫
                           shipWhseCode,
                           "11", // 支給先
                           shipToCode,
                           shippingMethodCode, // 設定した配送区分
                           shippedDate,
                           XxcmnUtility.getProfileValue(getOADBTransaction(), "XXCMN_ITEM_DIV_SECURITY"));
        /******************
         * 容積積載効率をセット
         ******************/
        loadEfficiencyCapacity = (String)params4.get("loadEfficiencyCapacity"); // 容積積載効率
      }
// 2009-02-13 H.Itou ADD END
      // 更新処理(合計数量、ラベル枚数、小口個数、積載重量合計、積載容積合計)
// 2009-02-19 H.Itou MOD START 本番障害#863 配車解除されない場合もあるので積載効率も更新する。
//      XxpoUtility.updateSummaryInfo(getOADBTransaction(),
//                                    orderHeaderId,
//                                    sumQuantity,
//                                    smallQuantity,
//                                    labelQuantity,
//                                    sumWeight,
//                                    sumCapacity);
      updateSummaryInfo(orderHeaderId,
                        sumQuantity,
                        smallQuantity,
                        labelQuantity,
                        sumWeight,
                        sumCapacity,
                        loadEfficiencyWeight,
                        loadEfficiencyCapacity);
// 2009-02-13 H.Itou MOD END
      /******************
       * 配車解除処理
       ******************/
// 2009-02-13 H.Itou Add Mod Start 本番障害#863対応 明細を削除した場合は、解除する必要があるか判断する。
//      String retCode = XxwshUtility.cancelCareersSchedile(
      String retCode = XxwshUtility.careerCancelOrUpd(
// 2009-02-13 H.Itou Add Mod End
                         getOADBTransaction(),
                         XxcmnConstants.BIZ_TYPE_PROV,
                         reqNo);
      // パラメータチェックエラーの場合
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // 予期せぬエラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // 配車処理失敗の場合
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAN_CAREERS);

      }

      // コミット処理
      doCommit(reqNo);

      // 削除処理成功メッセージを表示
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);

    }
  } // doDeleteLine

  /***************************************************************************
   * 支給指示作成明細画面の検索処理を行うメソッドです。
   * @param  exeType - 起動タイプ
   ***************************************************************************
   */
  public void doSearchLine(String exeType)
  {
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID

    // 支給指示作成明細VO取得
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // 検索を実行します。
    vo.initQuery(exeType, orderHeaderId);
    vo.first();
    // 1行も存在しない場合、1行作成
    if (vo.getFetchedRowCount() == 0) 
    {
      addRow(exeType);

    }

    // 支給指示作成合計VO取得
    XxpoProvisionInstMakeTotalVOImpl totalVo = getXxpoProvisionInstMakeTotalVO1();
    // 検索を実行します。
    totalVo.initQuery(orderHeaderId);

  } // doSearchLine

  /***************************************************************************
   * 支給指示作成明細画面の新規時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventInsLine(
    String exeType,
    OARow prow
    )
  {
    // 起動タイプが「11：伊藤園用」以外の場合
    if (!XxpoConstants.EXE_TYPE_11.equals(exeType)) 
    {
      // 項目制御
      prow.setAttribute("UnitPriceColRender" , Boolean.FALSE); // 単価列

    }
  } // handleEventInsHdr

  /***************************************************************************
   * 支給指示作成明細画面の更新時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param prow    - PVO行クラス
   * @param hdrRow  - ヘッダVO行クラス
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void handleEventUpdLine(
    String exeType,
    OARow prow,
    OARow hdrRow
    ) throws OAException
  {
    // 初期化
    handleEventAllOnLine(prow);
    // ステータスを取得
    String transStatus = (String)hdrRow.getAttribute("TransStatus");

    // 起動タイプが「11：伊藤園用」以外の場合
    if (!XxpoConstants.EXE_TYPE_11.equals(exeType)) 
    {
      // 項目制御
      prow.setAttribute("UnitPriceColRender" , Boolean.FALSE); // 単価列
    }

    // ステータスが「受領済」の場合 
    if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // 発注Noを取得
      String poNo = (String)hdrRow.getAttribute("PoNo");
      // 起動タイプが「11：伊藤園用」以外の場合
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // 発注有の場合
        if (!XxcmnUtility.isBlankOrNull(poNo)) 
        {
          // ボタン制御
          prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // 行挿入ボタン
        }

      // 起動タイプが「12：パッカー･外注工場用」の場合
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // 参照のみ
        handleEventAllOffLine(prow);

      // 起動タイプが「15：資材メーカー用」の場合
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // 発注有の場合
        if (!XxcmnUtility.isBlankOrNull(poNo)) 
        {
          // ボタン制御
          prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // 行挿入ボタン
        }
      }

    // ステータスが「出荷実績計上済」の場合 
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus))
    {
      // 起動タイプが「12：パッカー･外注工場用」の場合
      if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // 参照のみ
        handleEventAllOffLine(prow);

      } else
      {
        // 金額確定を取得
        String fixClass  = (String)hdrRow.getAttribute("FixClass");  

        // 金額確定済の場合
        if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
        {
          // 起動タイプが「11：伊藤園用」以外の場合
          if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
          {
            // ボタン制御
            prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // 行挿入ボタン

          } else 
          {
            // 参照のみ
            handleEventAllOffLine(prow);
          }
        }
      }
    }
  } // handleEventUpdLine

  /***************************************************************************
   * 支給指示作成明細画面の項目を全てFALSEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOnLine(OARow prow)
  {
    prow.setAttribute("UnitPriceColRender" , Boolean.TRUE);  // 単価列
    prow.setAttribute("ApplyBtnReject"     , Boolean.FALSE); // 適用ボタン
    prow.setAttribute("AddRowBtnRender"    , Boolean.TRUE); // 行挿入ボタン

  } // handleEventAllOnLine

  /***************************************************************************
   * 支給指示作成明細画面の項目を全てTRUEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOffLine(OARow prow)
  {
    prow.setAttribute("UnitPriceColRender" , Boolean.FALSE); // 単価列
    prow.setAttribute("ApplyBtnReject"     , Boolean.TRUE);  // 適用ボタン
    prow.setAttribute("AddRowBtnRender"    , Boolean.FALSE);  // 行挿入ボタン

  } // handleEventAllOnLine

  /***************************************************************************
   * 支給指示明細画面の適用処理を行うメソッドです。
   * @param  exeType - 起動タイプ
   * @return  HashMap - 戻り値群
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
    ) throws OAException
  {
    boolean exeFlag = false; // 実行フラグ

    // チェック処理
    chkOrderLine(exeType);

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow   = (OARow)hdrVo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // 新規フラグ
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // 依頼No
    String tokenName = null;

    // 新規フラグが「N：更新」の場合
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // 排他チェック
      chkLockAndExclusive(hdrVo, hdrRow);
      tokenName = XxpoConstants.TOKEN_NAME_UPD;

    // 新規の場合
    } else
    {
      // 依頼Noを取得
      reqNo = XxcmnUtility.getSeqNo(getOADBTransaction(), XxpoConstants.TOKEN_NAME_REQUEST_NO);
      // 受注ヘッダアドオンIDを取得
      Number orderHeaderId = XxpoUtility.getOrderHeaderId(getOADBTransaction());

      // rowに設定
      hdrRow.setAttribute("RequestNo", reqNo);
      hdrRow.setAttribute("OrderHeaderId", orderHeaderId);

      tokenName = XxpoConstants.TOKEN_NAME_INS;

    }

    // 依頼数⇒指示数コピー処理
    doCopyReqQty();

    // 追加・更新処理
    if (doExecute(newFlag, hdrRow, exeType)) 
    {
      // コミット処理
      XxpoUtility.commit(getOADBTransaction());

    } else
    {
      // ロールバック処理
      XxpoUtility.rollBack(getOADBTransaction());
      tokenName = null;

    }

    HashMap retParams = new HashMap();
    retParams.put("tokenName", tokenName); // トークン名称
    retParams.put("reqNo",     reqNo);     // 依頼No

    return retParams;

  } // doApply

  /***************************************************************************
   * 挿入・更新処理を行うメソッドです。
   * @param newFlag  - 新規フラグ Y:新規、N:更新
   * @param hdrRow   - ヘッダ行オブジェクト
   * @param exeType  - 起動タイプ
   * @return boolean - 処理実行フラグ true:実行
   *                                false:未実行
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean doExecute(
    String newFlag,
    OARow  hdrRow,
    String exeType
    ) throws OAException
  {
    boolean sumQtyFlag            = false; // 合計数量変更フラグ
    boolean lineExeFlag           = false; // 明細実行フラグ
    boolean hdrExeFlag            = false; // ヘッダ実行フラグ
    boolean cancelCarriersFlag    = false; // 配車解除フラグ
    boolean changeHdrFlag         = false; // 重要ヘッダ項目変更フラグ
    boolean changeLineFlag        = false; // 重要明細項目変更フラグ
    boolean setMaxShipToFlag      = false; // 最大配送区分設定フラグ
    boolean freightOnFlag         = false; // 運賃区分「対象外⇒対象」設定フラグ
    boolean freightOffFlag        = false; // 運賃区分「対象⇒対象外」設定フラグ
// 2008-10-27 D.Nihei ADD START
    boolean updNotifStatusFlag    = false; // 通知ステータス更新フラグ
// 2008-10-27 D.Nihei ADD END
// 2009-02-13 H.Itou ADD START 本番障害#863対応
    boolean careerCancelOrUpdFlag    = false; // 配車解除判断実行フラグ
// 2009-02-13 H.Itoui ADD END

    /****************************
     * ヘッダ各種情報取得
     ****************************/
    String rcvType            = (String)hdrRow.getAttribute("RcvType");             // 受領タイプ
    String transStatus        = (String)hdrRow.getAttribute("TransStatus");         // ステータス
    String freightClass       = (String)hdrRow.getAttribute("FreightChargeClass");  // 運賃区分
    String dbFreightClass     = (String)hdrRow.getAttribute("DbFreightChargeClass");// 運賃区分(DB)
    String vendorCode         = (String)hdrRow.getAttribute("VendorCode");          // 取引先
    String weightCapaClass    = (String)hdrRow.getAttribute("WeightCapacityClass"); // 重量容積区分
    String shipToCode         = (String)hdrRow.getAttribute("ShipToCode");          // 配送先
    String shipWhseCode       = (String)hdrRow.getAttribute("ShipWhseCode");        // 出庫倉庫
    Date shippedDate          = (Date)hdrRow.getAttribute("ShippedDate");           // 出庫日
    String reqNo              = (String)hdrRow.getAttribute("RequestNo");           // 依頼No
    Object freightCarrierCode = hdrRow.getAttribute("FreightCarrierCode");          // 運送業者
    Date arrivalDate          = (Date)hdrRow.getAttribute("ArrivalDate");           // 入庫日

    /****************************
     * 運賃区分判定
     ****************************/
    // 新規の場合
    if (XxcmnUtility.isBlankOrNull(dbFreightClass)) 
    {
      // 運賃区分(DB)に「対象外」を設定
      dbFreightClass = XxcmnConstants.STRING_ZERO;  
    }
    // 「対象外」⇒「対象」になった場合
    if (XxcmnUtility.chkCompareNumeric(1, freightClass, dbFreightClass)) 
    {
      freightOnFlag = true;

    // 「対象」⇒「対象外」になった場合
    } else if (XxcmnUtility.chkCompareNumeric(1, dbFreightClass, freightClass))
    {
      freightOffFlag = true;

    }
    /****************************
     * 重要ヘッダ項目変更判定(取引先、配送先、出庫倉庫、出庫日、入庫日、運送業者)
     ****************************/
    if (!XxcmnUtility.isEquals(vendorCode,         hdrRow.getAttribute("DbVendorCode"))
     || !XxcmnUtility.isEquals(shipToCode,         hdrRow.getAttribute("DbShipToCode"))
     || !XxcmnUtility.isEquals(shipWhseCode,       hdrRow.getAttribute("DbShipWhseCode"))
     || !XxcmnUtility.isEquals(shippedDate,        hdrRow.getAttribute("DbShippedDate"))
     || !XxcmnUtility.isEquals(arrivalDate,        hdrRow.getAttribute("DbArrivalDate"))
     || !XxcmnUtility.isEquals(freightCarrierCode, hdrRow.getAttribute("DbFreightCarrierCode"))) 
    {
      changeHdrFlag = true;

    }

    // 支給指示作成明細VO
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();

    /****************************
     * 明細更新行取得
     ****************************/
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if (updRows != null || updRows.length > 0) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++)
      {
        // i番目の行を取得
        updRow = (OARow)updRows[i];

        /******************
         * 明細各種情報取得
         ******************/
        Object itemId         = updRow.getAttribute("ItemId");                // 品目ID
        Object dbItemId       = updRow.getAttribute("DbItemId");              // 品目ID(DB)
        Object futaiCode      = updRow.getAttribute("FutaiCode");             // 付帯コード
        Object dbFutaiCode    = updRow.getAttribute("DbFutaiCode");           // 付帯コード(DB)
        Object reqQuantity    = updRow.getAttribute("ReqQuantity");           // 依頼数
        Object dbReqQuantity  = updRow.getAttribute("DbReqQuantity");         // 依頼数(DB)
        Object unitPriceNum   = updRow.getAttribute("UnitPriceNum");          // 単価
        Object dbUnitPriceNum = updRow.getAttribute("DbUnitPriceNum");        // 単価(DB)
        Object description    = updRow.getAttribute("LineDescription");       // 備考
        Object dbDescription  = updRow.getAttribute("DbLineDescription");     // 備考(DB)
        String instQuantity   = (String)updRow.getAttribute("InstQuantity");  // 指示数
        String dbInstQuantity = (String)updRow.getAttribute("DbInstQuantity");// 指示数(DB)

        // 重要明細項目変更判定(品目ID、依頼数)
        if (!XxcmnUtility.isEquals(itemId,      dbItemId)
         || !XxcmnUtility.isEquals(reqQuantity, dbReqQuantity)) 
        {
          // 重要明細項目変更フラグをtrueに変更
          changeLineFlag = true;  

        }
        // 品目ID、依頼数、付帯コード、単価、備考が変更された場合
        if ( changeLineFlag
         || !XxcmnUtility.isEquals(futaiCode,    dbFutaiCode)
         || !XxcmnUtility.isEquals(unitPriceNum, dbUnitPriceNum)
         || !XxcmnUtility.isEquals(description,  dbDescription)) 
        {
          // 配車解除要否判定(品目ID)
          if (!XxcmnUtility.isEquals(itemId, dbItemId))
          {
// 2009-02-13 H.Itou ADD START 本番障害#863対応 重量を変更した場合は解除する必要があるか判断する。
//            // 配車解除フラグをtrueにする
//            cancelCarriersFlag = true;  
          // 配車解除判断実行フラグをtrueに変更
          careerCancelOrUpdFlag = true;
// 2009-02-13 H.Itou ADD END
          }

          // 更新処理
          updateOrderLine(updRow);

          // 明細実行フラグをtrueに変更
          lineExeFlag = true;

        }
        // 指示数が変更された場合
        if (!XxcmnUtility.isEquals(XxcmnUtility.commaRemoval(instQuantity), 
// 2009-02-13 H.Itou MOD START
//                                   XxcmnUtility.commaRemoval(dbInstQuantity)))
                                   XxcmnUtility.commaRemoval(dbInstQuantity))
         || !XxcmnUtility.isEquals(itemId, dbItemId))
// 2009-02-13 H.Itou MOD END
        {
          // 合計数量変更フラグをtrueに変更
          sumQtyFlag = true;

        }
      }
    }

    /****************************
     * 明細追加行取得
     ****************************/
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0)) 
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++)
      {
        // i番目の行を取得
        insRow = (OARow)insRows[i];

        /******************
         * 明細各種情報取得
         ******************/
        Object itemNo      = insRow.getAttribute("ItemNo");          // 品目ID
        Object futaiCode   = insRow.getAttribute("FutaiCode");       // 付帯
        Object reqQuantity = insRow.getAttribute("ReqQuantity");     // 依頼数
        Object description = insRow.getAttribute("LineDescription"); // 備考
        
        // いずれかの項目が入力されている場合
        if (!XxcmnUtility.isBlankOrNull(itemNo)
         || !XxcmnUtility.isBlankOrNull(reqQuantity)
         || !XxcmnUtility.isBlankOrNull(description)) 
        {
// 2009-02-13 H.Itou MOD START
          // 重要明細項目変更フラグをtrueに変更
          changeLineFlag = true;
// 2009-02-13 H.Itou MOD END
          // 配車解除要否判定(配車済の場合)
          if (XxpoConstants.RCV_TYPE_3.equals(rcvType)
           || XxpoConstants.RCV_TYPE_4.equals(rcvType)) 
          {
// 2009-02-13 H.Itou MOD START 本番障害#863対応 重量を変更した場合は解除する必要があるか判断する。
//            // 配車解除フラグをtrueにする
//            cancelCarriersFlag = true;  
            // 配車解除判断実行フラグをtrueに変更
            careerCancelOrUpdFlag = true;
// 2009-02-13 H.Itou MOD END

          }
// 2008-10-27 D.Nihei ADD START
          // 「受領済」時に明細が追加された場合
          if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus)) 
          {
            // 通知ステータス更新フラグをtrueにする
            updNotifStatusFlag = true; 
          }
// 2008-10-27 D.Nihei ADD RND
          // 挿入処理
          insertOrderLine(hdrRow, insRow);

          // 明細実行フラグをtrueに変更
          lineExeFlag = true;

          // 合計数量変更フラグをtrueに変更
          sumQtyFlag = true;

          // ステータスが「出荷実績計上済」の場合は、フラグを立てない。
// 2009-02-13 H.Itou MOD START
//          if (!XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
          if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
// 2009-02-13 H.Itou MOD END
          {
            // 重要明細項目変更フラグをfalseに変更
            changeLineFlag = false;  

          }
        // それ以外
        } else
        {
          // 不要行削除
          insRow.remove();

        }
      }
    }
    // 明細件数が0件の場合
    if (vo.getFetchedRowCount() == 0) 
    {
      // 行追加  
      addRow(exeType);
      // エラー処理
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10146);
      
    }
    
    /****************************
     * 配車関連情報導出判定
     ****************************/
    if (changeHdrFlag || changeLineFlag || freightOnFlag) 
    {
      /******************
       * 配車関連情報設定
       ******************/
      setCarriersData(hdrRow);

    }

    // 運賃区分が「対象」の場合
    if (XxcmnUtility.isEquals(freightClass, XxcmnConstants.OBJECT_ON)) 
    {
      /******************
       * 最大配送区分取得
       ******************/
      HashMap paramsRet = XxpoUtility.getMaxShipMethod(
                            getOADBTransaction(),
                            "4",  // 倉庫
                            shipWhseCode,
                            "11", // 支給先
                            shipToCode,
                            weightCapaClass,
                            null,
                            shippedDate); 
      // 最大配送区分をセットする
      String maxShipToCode = (String)paramsRet.get("maxShipMethods");
      // 最大配送区分が取得できなかった場合
      if (XxcmnUtility.isBlankOrNull(maxShipToCode)) 
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        // エラーメッセージ出力
        MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                   "最大配送区分の取得") };
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN05002,
                              tokens);
    
      // ヘッダの重要項目が変更された、または配送区分が設定されていない場合にのみ設定
      } else if (changeHdrFlag || XxcmnUtility.isBlankOrNull(hdrRow.getAttribute("ShippingMethodCode"))) 
      {
        /******************
         * 各項目をセット
         ******************/
        hdrRow.setAttribute("ShippingMethodCode", paramsRet.get("maxShipMethods"));  // 配送区分
        hdrRow.setAttribute("BasedWeight",        paramsRet.get("deadweight"));      // 基本重量
        hdrRow.setAttribute("BasedCapacity",      paramsRet.get("loadingCapacity")); // 基本容積
        setMaxShipToFlag = true;

      }
      // 積載効率チェック(積載効率算出)実施判定
      if (freightOnFlag || changeHdrFlag || changeLineFlag)
      {
        // 重量容積区分によって渡すパラメータをかえる
// 2009-02-13 H.Itou MOD START 本番障害#1184 積載効率チェックは、重量容積区分の一致する側のみ行うため、2008-07-29の削除を復活。
// 2008-07-29 D.Nihei DEL START
        String sumWeight   = null;
        String sumCapacity = null;
        // 重量容積区分が、「重量」の場合
        if (XxpoConstants.WGHT_CAPA_CLASS_WEIGHT.equals(weightCapaClass)) 
        {
          sumWeight   = (String)hdrRow.getAttribute("SumWeight");
        // それ以外
        } else 
        {
          sumCapacity = (String)hdrRow.getAttribute("SumCapacity");
        }
// 2008-07-29 D.Nihei DEL END
// 2009-02-13 H.Itou MOD END
        /******************
         * 積載効率チェック(積載オーバーはXxpoUtility関数内でチェックしている。)
         ******************/
        HashMap params1 = XxpoUtility.calcLoadEfficiency(
                           getOADBTransaction(),
// 2009-02-13 H.Itou MOD START 本番障害#1184 積載効率チェックは、重量容積区分の一致する側のみ行うため、2008-07-29の削除を復活。
// 2008-07-29 D.Nihei MOD START
                           sumWeight,
                           sumCapacity,
//                           (String)hdrRow.getAttribute("SumWeight"),
//                           null,
// 2008-07-29 D.Nihei MOD END
// 2009-02-13 H.Itou MOD END
                           "4",  // 倉庫
                           shipWhseCode,
                           "11", // 支給先
                           shipToCode,
                           maxShipToCode,
                           shippedDate,
                           true);
// 2009-02-13 H.Itou DEL START 本番障害#863 ヘッダにセットする積載効率は最大配送区分で計算しない。
//        /******************
//         * 各項目をセット
//         ******************/
//        hdrRow.setAttribute("EfficiencyWeight",   params1.get("loadEfficiencyWeight"));   // 重量積載効率
// 2009-02-13 H.Itou DEL END
// 2009-02-13 H.Itou DEL START 本番障害#1184 積載効率チェックは、重量容積区分の一致する側のみ行うため削除。
// 2008-07-29 D.Nihei ADD START
//        /******************
//         * 容積積載効率チェック(積載効率算出)
//         ******************/
//        HashMap params2 = XxpoUtility.calcLoadEfficiency(
//                           getOADBTransaction(),
//                           null,
//                           (String)hdrRow.getAttribute("SumCapacity"),
//                           "4",  // 倉庫
//                           shipWhseCode,
//                           "11", // 支給先
//                           shipToCode,
//                           maxShipToCode,
//                           shippedDate,
//                           true);
// 2009-02-13 H.Itou DEL END
// 2009-02-13 H.Itou DEL START 本番障害#863 ヘッダにセットする積載効率は最大配送区分で計算しない。
//        /******************
//         * 各項目をセット
//         ******************/
//// 2008-07-29 D.Nihei ADD END
//        hdrRow.setAttribute("EfficiencyCapacity", params2.get("loadEfficiencyCapacity")); // 容積積載効率
// 2009-02-13 H.Itou DEL END
// 2009-02-13 H.Itou ADD START 本番障害#863
        /******************
         * 重量積載効率算出(積載オーバーでもエラーとならないXxwshUtilityの関数を使用)
         ******************/
        HashMap params3 = XxwshUtility.calcLoadEfficiency(
                           getOADBTransaction(),
                           (String)hdrRow.getAttribute("SumWeight"),
                           null,
                           "4",  // 倉庫
                           shipWhseCode,
                           "11", // 支給先
                           shipToCode,
                           (String)hdrRow.getAttribute("ShippingMethodCode"), // 設定した配送区分,
                           shippedDate,
                           XxcmnUtility.getProfileValue(getOADBTransaction(), "XXCMN_ITEM_DIV_SECURITY"));
        /******************
         * 重量積載効率をセット
         ******************/
        hdrRow.setAttribute("EfficiencyWeight",   params3.get("loadEfficiencyWeight"));   // 重量積載効率

        /******************
         * 容積積載効率算出(積載オーバーでもエラーとならないXxwshUtilityの関数を使用)
         ******************/
        HashMap params4 = XxwshUtility.calcLoadEfficiency(
                           getOADBTransaction(),
                           null,
                           (String)hdrRow.getAttribute("SumCapacity"),
                           "4",  // 倉庫
                           shipWhseCode,
                           "11", // 支給先
                           shipToCode,
                           (String)hdrRow.getAttribute("ShippingMethodCode"), // 設定した配送区分
                           shippedDate,
                           XxcmnUtility.getProfileValue(getOADBTransaction(), "XXCMN_ITEM_DIV_SECURITY"));
        /******************
         * 容積積載効率をセット
         ******************/
        hdrRow.setAttribute("EfficiencyCapacity", params4.get("loadEfficiencyCapacity")); // 容積積載効率
// 2009-02-13 H.Itou ADD END
      }
    }
    /****************************
     * ヘッダ新規追加・更新処理
     ****************************/
    // ヘッダ新規追加の場合
    if (XxcmnConstants.STRING_Y.equals(newFlag)) 
    {
      /******************
       * 挿入処理
       ******************/
      insertOrderHdr(hdrRow);
      // ヘッダ実行フラグをtrueに変更
      hdrExeFlag = true;
      
    // ヘッダ更新の場合
    } else
    {
      /******************
       * ヘッダ各種情報取得
       ******************/
      Object orderTypeId  = hdrRow.getAttribute("OrderTypeId");        // 発生区分
      Object reqDeptCode  = hdrRow.getAttribute("ReqDeptCode");        // 依頼部署
      Object instDeptCode = hdrRow.getAttribute("InstDeptCode");       // 指示部署
    
      // 以下が変更された場合
      // ・発生区分 ・重量容積区分 ・依頼部署    ・指示部署 ・取引先
      // ・配送先   ・出庫倉庫    ・運送業者    ・出庫日   ・入庫日
      // ・着荷時間(From)        ・着荷時間(To)・配送区分 ・運賃区分
      // ・引取区分 ・製造日      ・製造品目    ・製造番号 ・摘要
      // ・指示受領 ・金額確定    ・合計数量変更フラグsumQtyFlag
      if ( changeHdrFlag
       || !XxcmnUtility.isEquals(orderTypeId,        hdrRow.getAttribute("DbOrderTypeId"))
       || !XxcmnUtility.isEquals(weightCapaClass,    hdrRow.getAttribute("DbWeightCapacityClass"))
       || !XxcmnUtility.isEquals(reqDeptCode,        hdrRow.getAttribute("DbReqDeptCode"))
       || !XxcmnUtility.isEquals(instDeptCode,       hdrRow.getAttribute("DbInstDeptCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeFrom"),      hdrRow.getAttribute("DbArrivalTimeFrom"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeTo"),        hdrRow.getAttribute("DbArrivalTimeTo"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingMethodCode"),   hdrRow.getAttribute("DbShippingMethodCode"))
       || !XxcmnUtility.isEquals(freightClass,       dbFreightClass)
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("TakebackClass"),        hdrRow.getAttribute("DbTakebackClass"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedProdDate"),   hdrRow.getAttribute("DbDesignatedProdDate"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedItemCode"),   hdrRow.getAttribute("DbDesignatedItemCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedBranchNo"),   hdrRow.getAttribute("DbDesignatedBranchNo"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("RcvClass"),             hdrRow.getAttribute("DbRcvClass"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("FixClass"),             hdrRow.getAttribute("DbFixClass"))
       || sumQtyFlag) 
      {
        /******************
         * 配車関連情報クリア判定
         ******************/
        if (freightOffFlag) 
        {
          // 配車関連情報をクリア
          hdrRow.setAttribute("ShippingMethodCode", null); // 配送区分
          hdrRow.setAttribute("EfficiencyWeight",   null); // 重量積載効率
          hdrRow.setAttribute("EfficiencyCapacity", null); // 容積積載効率
          hdrRow.setAttribute("BasedWeight",        null); // 基本重量
          hdrRow.setAttribute("BasedCapacity",      null); // 基本容積

        }
        /******************
         * 更新処理
         ******************/
        updateOrderHdr(hdrRow);

// 2009-01-22 v1.13 T.Yoshimoto Add Start 本番#739
        // 有償金額確定区分が「確定」の場合
        String fixClass       = (String)hdrRow.getAttribute("FixClass");      // 有償金額確定
        Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
        if (XxpoConstants.FIX_CLASS_ON.equals(fixClass))
        {
          Date updateArrivalDate = getUpdateArrivalDate(hdrRow);

          XxpoUtility.updArrivalDate(
            getOADBTransaction(),
            orderHeaderId,
            updateArrivalDate);

          // 有償金額確定処理を実行します。
          XxpoUtility.updateFixClass(
            getOADBTransaction(),
            orderHeaderId,
            XxpoConstants.FIX_CLASS_ON);
        }
// 2009-01-22 v1.13 T.Yoshimoto Add End 本番#739

        // ヘッダ実行フラグをtrueに変更
        hdrExeFlag = true;

      }
    }
    /******************
     * 配車解除判定
     ******************/
    // 受領タイプがNull以外、「運賃区分」を対象⇒対象外にした、
    // または、ヘッダの重要項目が変更された場合
    if (!XxcmnUtility.isBlankOrNull(rcvType) 
     && (freightOffFlag || changeHdrFlag)) 
    {
      // 配車解除フラグをtrueにする
      cancelCarriersFlag = true;

    // 配送NoがNullでヘッダ、明細の重要項目が変更された場合
    } else if (XxcmnUtility.isBlankOrNull(hdrRow.getAttribute("ShipToNo"))
// 2008-10-27 D.Nihei MOD START
//            && (hdrExeFlag || lineExeFlag))
            && (changeHdrFlag || changeLineFlag))
// 2008-10-27 D.Nihei MOD END
    {
      // 配車解除フラグをtrueにする
      cancelCarriersFlag = true;

    }
// 2008-10-27 D.Nihei ADD START
    // 運賃区分が対象外⇒対象,、着荷時間From、着荷時間TO、摘要が変更された場合
    if (freightOnFlag
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeFrom"),      hdrRow.getAttribute("DbArrivalTimeFrom"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeTo"),        hdrRow.getAttribute("DbArrivalTimeTo"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions"))) 
    {
      // 通知ステータス更新フラグをtrueにする
      updNotifStatusFlag = true; 
    }
// 2008-10-27 D.Nihei ADD END

    /******************
     * 配車解除処理
     ******************/
    if (cancelCarriersFlag) 
    {
      String retCode = XxwshUtility.cancelCareersSchedile(
                         getOADBTransaction(),
                         XxcmnConstants.BIZ_TYPE_PROV,
                         reqNo);
      // パラメータチェックエラーの場合
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // 予期せぬエラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // 配車処理失敗の場合
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAN_CAREERS);

      }
// 2009-02-13 H.Itou ADD START 本番障害#863対応
    } else if (careerCancelOrUpdFlag)
    {
      // 配車解除判定関数を実行する。
      String retCode = XxwshUtility.careerCancelOrUpd(
                         getOADBTransaction(),
                         XxcmnConstants.BIZ_TYPE_PROV,
                         reqNo);
      // パラメータチェックエラーの場合
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // 予期せぬエラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // 配車処理失敗の場合
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAN_CAREERS);

      }
// 2009-02-13 H.Itou ADD END
// 2008-10-27 D.Nihei ADD START
    } else if (updNotifStatusFlag)
    {
      // 通知ステータス更新関数を実行する。
      XxwshUtility.updateNotifStatus(
        getOADBTransaction(),
        XxcmnConstants.BIZ_TYPE_PROV,
        reqNo);
// 2008-10-27 D.Nihei ADD END
    }

    return (hdrExeFlag || lineExeFlag);

  } // doExecute

  /*****************************************************************************
   * 受注ヘッダアドオンにデータを追加します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void insertOrderHdr(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "insertOrderHdr";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_headers_all(");
    sb.append("    order_header_id            "); // 受注ヘッダアドオンID
    sb.append("   ,order_type_id              "); // 受注タイプID
    sb.append("   ,organization_id            "); // 組織ID
    sb.append("   ,latest_external_flag       "); // 最新フラグ
    sb.append("   ,ordered_date               "); // 受注日
    sb.append("   ,customer_id                "); // 顧客ID
    sb.append("   ,customer_code              "); // 顧客
    sb.append("   ,shipping_instructions      "); // 出荷指示
    sb.append("   ,career_id                  "); // 運送業者ID
    sb.append("   ,freight_carrier_code       "); // 運送業者
    sb.append("   ,shipping_method_code       "); // 配送区分
    sb.append("   ,request_no                 "); // 依頼No
    sb.append("   ,base_request_no            "); // 元依頼No
    sb.append("   ,req_status                 "); // ステータス
    sb.append("   ,schedule_ship_date         "); // 出荷予定日
    sb.append("   ,schedule_arrival_date      "); // 着荷予定日
    sb.append("   ,freight_charge_class       "); // 運賃区分
    sb.append("   ,shikyu_inst_rcv_class      "); // 支給指示受領区分
    sb.append("   ,amount_fix_class           "); // 有償金額確定区分
    sb.append("   ,takeback_class             "); // 引取区分
    sb.append("   ,deliver_from_id            "); // 出荷元ID
    sb.append("   ,deliver_from               "); // 出荷元保管場所
    sb.append("   ,prod_class                 "); // 商品区分
    sb.append("   ,arrival_time_from          "); // 着荷時間FROM
    sb.append("   ,arrival_time_to            "); // 着荷時間TO
    sb.append("   ,designated_item_id         "); // 製造品目ID
    sb.append("   ,designated_item_code       "); // 製造品目
    sb.append("   ,designated_production_date "); // 製造日
    sb.append("   ,designated_branch_no       "); // 製造枝番
    sb.append("   ,sum_quantity               "); // 合計数量
    sb.append("   ,small_quantity             "); // 小口個数
    sb.append("   ,label_quantity             "); // ラベル枚数
    sb.append("   ,loading_efficiency_weight  "); // 重量積載効率
    sb.append("   ,loading_efficiency_capacity"); // 容積積載効率
    sb.append("   ,based_weight               "); // 基本重量
    sb.append("   ,based_capacity             "); // 基本容積
    sb.append("   ,sum_weight                 "); // 積載重量合計
    sb.append("   ,sum_capacity               "); // 積載容積合計
    sb.append("   ,weight_capacity_class      "); // 重量容積区分
    sb.append("   ,actual_confirm_class       "); // 実績計上済区分
    sb.append("   ,notif_status               "); // 通知ステータス
    sb.append("   ,new_modify_flg             "); // 新規修正フラグ
    sb.append("   ,performance_management_dept"); // 成績管理部署
    sb.append("   ,instruction_dept           "); // 指示部署
    sb.append("   ,vendor_id                  "); // 取引先ID
    sb.append("   ,vendor_code                "); // 取引先
    sb.append("   ,vendor_site_id             "); // 取引先サイトID
    sb.append("   ,vendor_site_code           "); // 取引先サイト
    sb.append("   ,created_by                 "); // 作成者
    sb.append("   ,creation_date              "); // 作成日
    sb.append("   ,last_updated_by            "); // 最終更新者
    sb.append("   ,last_update_date           "); // 最終更新日
    sb.append("   ,last_update_login)         "); // 最終更新ログイン
    sb.append("  VALUES( ");
    sb.append("    :1 ");
    sb.append("   ,:2 ");
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') ");
    sb.append("   ,'Y' ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,:3 ");
    sb.append("   ,:4 ");
    sb.append("   ,:5 ");
    sb.append("   ,:6 ");
    sb.append("   ,:7 ");
    sb.append("   ,:8 ");
    sb.append("   ,:9 ");
    sb.append("   ,:10 ");
    sb.append("   ,'05' ");
    sb.append("   ,:11 ");
    sb.append("   ,:12 ");
    sb.append("   ,:13 ");
    sb.append("   ,:14 ");
    sb.append("   ,:15 ");
    sb.append("   ,:16 ");
    sb.append("   ,:17 ");
    sb.append("   ,:18 ");
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') ");
    sb.append("   ,:19 ");
    sb.append("   ,:20 ");
    sb.append("   ,:21 ");
    sb.append("   ,:22 ");
    sb.append("   ,:23 ");
    sb.append("   ,:24 ");
    sb.append("   ,TO_NUMBER(:25) ");
    sb.append("   ,TO_NUMBER(:26) ");
    sb.append("   ,TO_NUMBER(:27) ");
    sb.append("   ,TO_NUMBER(:28) ");
    sb.append("   ,TO_NUMBER(:29) ");
    sb.append("   ,TO_NUMBER(:30) ");
    sb.append("   ,TO_NUMBER(:31) ");
    sb.append("   ,TO_NUMBER(:32) ");
    sb.append("   ,TO_NUMBER(:33) ");
    sb.append("   ,:34 ");
    sb.append("   ,'N' ");
    sb.append("   ,'10' ");
    sb.append("   ,'N' ");
    sb.append("   ,:35 ");
    sb.append("   ,:36 ");
    sb.append("   ,:37 ");
    sb.append("   ,:38 ");
    sb.append("   ,:39 ");
    sb.append("   ,:40 ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.LOGIN_ID); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number orderHeaderId       = (Number)hdrRow.getAttribute("OrderHeaderId");         // 受注ヘッダアドオンID
      Number orderTypeId         = (Number)hdrRow.getAttribute("OrderTypeId");           // 発生区分
      Number customerId          = (Number)hdrRow.getAttribute("CustomerId");            // 顧客ID
      String customerCode        = (String)hdrRow.getAttribute("CustomerCode");          // 顧客
      String instructions        = (String)hdrRow.getAttribute("ShippingInstructions");  // 摘要
      Number freightCarrierId    = (Number)hdrRow.getAttribute("FreightCarrierId");      // 運送業者ID
      String freightCarrierCode  = (String)hdrRow.getAttribute("FreightCarrierCode");    // 運送業者
      String shippingMethodCode  = (String)hdrRow.getAttribute("ShippingMethodCode");    // 配送区分
      String requestNo           = (String)hdrRow.getAttribute("RequestNo");             // 依頼No
      String baseRequestNo       = (String)hdrRow.getAttribute("BaseRequestNo");         // 元依頼No
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // 出庫予定日
      Date   arrivalDate         = (Date)hdrRow.getAttribute("ArrivalDate");             // 入庫予定日
      String freightChargeClass  = (String)hdrRow.getAttribute("FreightChargeClass");    // 運賃区分
      String rcvClass            = (String)hdrRow.getAttribute("RcvClass");              // 指示受領
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // 金額確定
      String takebackClass       = (String)hdrRow.getAttribute("TakebackClass");         // 引取区分
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // 出庫倉庫ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // 出庫倉庫
      String arrivalTimeFrom     = (String)hdrRow.getAttribute("ArrivalTimeFrom");       // 着荷時間From
      String arrivalTimeTo       = (String)hdrRow.getAttribute("ArrivalTimeTo");         // 着荷時間To
      Number designatedItemId    = (Number)hdrRow.getAttribute("DesignatedItemId");      // 製造品目ID(INV)
      String designatedItemCode  = (String)hdrRow.getAttribute("DesignatedItemCode");    // 製造品目No
      Date   designatedProdDate  = (Date)hdrRow.getAttribute("DesignatedProdDate");      // 製造日
      String designatedBranchNo  = (String)hdrRow.getAttribute("DesignatedBranchNo");    // 製造番号
      String sumQuantity         = (String)hdrRow.getAttribute("SumQuantity");           // 合計数量
      Number smallQuantity       = (Number)hdrRow.getAttribute("SmallQuantity");         // 小口個数
      Number labelQuantity       = (Number)hdrRow.getAttribute("LabelQuantity");         // ラベル枚数
      String efficiencyWeight    = (String)hdrRow.getAttribute("EfficiencyWeight");      // 重量積載効率
      String efficiencyCapacity  = (String)hdrRow.getAttribute("EfficiencyCapacity");    // 容積積載効率
      String basedWeight         = (String)hdrRow.getAttribute("BasedWeight");           // 基本重量
      String basedCapacity       = (String)hdrRow.getAttribute("BasedCapacity");         // 基本容積
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // 積載重量合計
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // 積載容積合計
      String weightCapacityClass = (String)hdrRow.getAttribute("WeightCapacityClass");   // 重量容積区分
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // 依頼部署
      String instDeptCode        = (String)hdrRow.getAttribute("InstDeptCode");          // 指示部署
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // 取引先ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // 取引先
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // 配送先ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // 配送先

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // 受注ヘッダアドオンID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId));      // 発生区分
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));       // 顧客ID
      cstmt.setString(i++, customerCode);                         // 顧客
      cstmt.setString(i++, instructions);                         // 摘要
      if (XxcmnUtility.isBlankOrNull(freightCarrierId)) 
      {
        cstmt.setNull(i++, Types.INTEGER); // 運送業者ID
      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(freightCarrierId)); // 運送業者ID
        
      }
      cstmt.setString(i++, freightCarrierCode);                   // 運送業者
      cstmt.setString(i++, shippingMethodCode);                   // 配送区分
      cstmt.setString(i++, requestNo);                            // 依頼No
      cstmt.setString(i++, baseRequestNo);                        // 元依頼No
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 出庫日
      cstmt.setDate(i++, XxcmnUtility.dateValue(arrivalDate));    // 入庫日
      cstmt.setString(i++, freightChargeClass);                   // 運賃区分
      cstmt.setString(i++, rcvClass);                             // 指示受領
      cstmt.setString(i++, fixClass);                             // 金額確定
      cstmt.setString(i++, takebackClass);                        // 引取区分
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // 出庫倉庫ID
      cstmt.setString(i++, shipWhseCode);                         // 出庫倉庫
      cstmt.setString(i++, arrivalTimeFrom);                      // 着荷時間From
      cstmt.setString(i++, arrivalTimeTo);                        // 着荷時間To
      if (XxcmnUtility.isBlankOrNull(designatedItemId)) 
      {
        cstmt.setNull(i++, Types.NUMERIC); // 製造品目ID(INV)

      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(designatedItemId)); // 製造品目ID(INV)

      }
      cstmt.setString(i++, designatedItemCode);                   // 製造品目No
      cstmt.setDate(i++, XxcmnUtility.dateValue(designatedProdDate)); // 製造日
      cstmt.setString(i++, designatedBranchNo);                       // 製造番号
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumQuantity));   // 合計数量
      cstmt.setString(i++, XxcmnUtility.stringValue(smallQuantity));  // 小口個数
      cstmt.setString(i++, XxcmnUtility.stringValue(labelQuantity));  // ラベル枚数
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyWeight));   // 重量積載効率
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyCapacity)); // 容積積載効率
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedWeight));   // 基本重量
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedCapacity)); // 基本容積
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumWeight));     // 積載重量合計
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumCapacity));   // 積載容積合計
      cstmt.setString(i++, weightCapacityClass);                  // 重量容積区分
      cstmt.setString(i++, reqDeptCode);                          // 依頼部署
      cstmt.setString(i++, instDeptCode);                         // 指示部署
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // 取引先ID
      cstmt.setString(i++, vendorCode);                           // 取引先
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // 配送先ID
      cstmt.setString(i++, shipToCode);                           // 配送先
     
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderHdr 

  /*****************************************************************************
   * 受注ヘッダアドオンにデータを追加します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void updateOrderHdr(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "updateOrderHdr";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET   xoha.order_type_id               = :1 " ); // 受注タイプID
    sb.append("       ,xoha.customer_id                 = :2 " ); // 顧客ID
    sb.append("       ,xoha.customer_code               = :3 " ); // 顧客
    sb.append("       ,xoha.shipping_instructions       = :4 " ); // 出荷指示
    sb.append("       ,xoha.career_id                   = :5 " ); // 運送業者ID
    sb.append("       ,xoha.freight_carrier_code        = :6 " ); // 運送業者
    sb.append("       ,xoha.shipping_method_code        = :7 " ); // 配送区分
    sb.append("       ,xoha.schedule_ship_date          = NVL(:8, xoha.schedule_ship_date)   "); // 出荷予定日
    sb.append("       ,xoha.schedule_arrival_date       = NVL(:9, xoha.schedule_arrival_date)"); // 着荷予定日
    sb.append("       ,xoha.freight_charge_class        = :10 " ); // 運賃区分
    sb.append("       ,xoha.amount_fix_class            = :11 " ); // 有償金額確定区分
    sb.append("       ,xoha.takeback_class              = :12 " ); // 引取区分
    sb.append("       ,xoha.deliver_from_id             = :13 " ); // 出荷元ID
    sb.append("       ,xoha.deliver_from                = :14 " ); // 出荷元保管場所
    sb.append("       ,xoha.arrival_time_from           = :15 " ); // 着荷時間FROM
    sb.append("       ,xoha.arrival_time_to             = :16 " ); // 着荷時間TO
    sb.append("       ,xoha.designated_item_id          = :17 " ); // 製造品目ID
    sb.append("       ,xoha.designated_item_code        = :18 " ); // 製造品目
    sb.append("       ,xoha.designated_production_date  = :19 " ); // 製造日
    sb.append("       ,xoha.designated_branch_no        = :20 " ); // 製造枝番
    sb.append("       ,xoha.sum_quantity                = TO_NUMBER(:21) " ); // 合計数量
    sb.append("       ,xoha.small_quantity              = TO_NUMBER(:22) " ); // 小口個数
    sb.append("       ,xoha.label_quantity              = TO_NUMBER(:23) " ); // ラベル枚数
    sb.append("       ,xoha.loading_efficiency_weight   = TO_NUMBER(:24) " ); // 重量積載効率
    sb.append("       ,xoha.loading_efficiency_capacity = TO_NUMBER(:25) " ); // 容積積載効率
    sb.append("       ,xoha.based_weight                = TO_NUMBER(:26) " ); // 基本重量
    sb.append("       ,xoha.based_capacity              = TO_NUMBER(:27) " ); // 基本容積
    sb.append("       ,xoha.sum_weight                  = TO_NUMBER(:28) " ); // 積載重量合計
    sb.append("       ,xoha.sum_capacity                = TO_NUMBER(:29) " ); // 積載容積合計
    sb.append("       ,xoha.performance_management_dept = :30 " ); // 成績管理部署
    sb.append("       ,xoha.instruction_dept            = :31 " ); // 指示部署
    sb.append("       ,xoha.vendor_id                   = :32 " ); // 取引先ID
    sb.append("       ,xoha.vendor_code                 = :33 " ); // 取引先
    sb.append("       ,xoha.vendor_site_id              = :34 " ); // 取引先サイトID
    sb.append("       ,xoha.vendor_site_code            = :35 " ); // 取引先サイト
    sb.append("       ,xoha.last_updated_by             = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("       ,xoha.last_update_date            = SYSDATE "             ); // 最終更新日
    sb.append("       ,xoha.last_update_login           = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE xoha.order_header_id = :36; "); // 受注ヘッダアドオンID
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number orderTypeId         = (Number)hdrRow.getAttribute("OrderTypeId");           // 発生区分
      Number customerId          = (Number)hdrRow.getAttribute("CustomerId");            // 顧客ID
      String customerCode        = (String)hdrRow.getAttribute("CustomerCode");          // 顧客
      String instructions        = (String)hdrRow.getAttribute("ShippingInstructions");  // 摘要
      Number freightCarrierId    = (Number)hdrRow.getAttribute("FreightCarrierId");      // 運送業者ID
      String freightCarrierCode  = (String)hdrRow.getAttribute("FreightCarrierCode");    // 運送業者
      String shippingMethodCode  = (String)hdrRow.getAttribute("ShippingMethodCode");    // 配送区分
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // 出庫予定日
      Date   arrivalDate         = (Date)hdrRow.getAttribute("ArrivalDate");             // 入庫予定日
      String freightChargeClass  = (String)hdrRow.getAttribute("FreightChargeClass");    // 運賃区分
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // 金額確定
      String takebackClass       = (String)hdrRow.getAttribute("TakebackClass");         // 引取区分
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // 出庫倉庫ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // 出庫倉庫
      String arrivalTimeFrom     = (String)hdrRow.getAttribute("ArrivalTimeFrom");       // 着荷時間From
      String arrivalTimeTo       = (String)hdrRow.getAttribute("ArrivalTimeTo");         // 着荷時間To
      Number designatedItemId    = (Number)hdrRow.getAttribute("DesignatedItemId");      // 製造品目ID(INV)
      String designatedItemCode  = (String)hdrRow.getAttribute("DesignatedItemCode");    // 製造品目No
      Date   designatedProdDate  = (Date)hdrRow.getAttribute("DesignatedProdDate");      // 製造日
      String designatedBranchNo  = (String)hdrRow.getAttribute("DesignatedBranchNo");    // 製造番号
      String sumQuantity         = (String)hdrRow.getAttribute("SumQuantity");           // 合計数量
      Number smallQuantity       = (Number)hdrRow.getAttribute("SmallQuantity");         // 小口個数
      Number labelQuantity       = (Number)hdrRow.getAttribute("LabelQuantity");         // ラベル枚数
      String efficiencyWeight    = (String)hdrRow.getAttribute("EfficiencyWeight");      // 重量積載効率
      String efficiencyCapacity  = (String)hdrRow.getAttribute("EfficiencyCapacity");    // 容積積載効率
      String basedWeight         = (String)hdrRow.getAttribute("BasedWeight");           // 基本重量
      String basedCapacity       = (String)hdrRow.getAttribute("BasedCapacity");         // 基本容積
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // 積載重量合計
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // 積載容積合計
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // 依頼部署
      String instDeptCode        = (String)hdrRow.getAttribute("InstDeptCode");          // 指示部署
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // 取引先ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // 取引先
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // 配送先ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // 配送先
      Number orderHeaderId       = (Number)hdrRow.getAttribute("OrderHeaderId");         // 受注ヘッダアドオンID
      Number resultFreightCarrierId   = (Number)hdrRow.getAttribute("DbResultFreightCarrierId");   // 運送業者ID(実績)
      String resultFreightCarrierCode = (String)hdrRow.getAttribute("DbResultFreightCarrierCode"); // 運送業者(実績)
      String resultShippingMethodCode = (String)hdrRow.getAttribute("DbResultShippingMethodCode"); // 配送区分(実績)
      Date   resultShippedDate        = (Date)hdrRow.getAttribute("DbResultShippedDate");          // 出庫日(実績)
      Date   resultArrivalDate        = (Date)hdrRow.getAttribute("DbResultArrivalDate");          // 入庫日(実績)
      String dbShippingMethodCode     = (String)hdrRow.getAttribute("DbShippingMethodCode");       // 配送区分(DB)
      Number planFreightCarrierId     = (Number)hdrRow.getAttribute("PlanFreightCarrierId");       // 運送業者ID(予定)
      String planFreightCarrierCode   = (String)hdrRow.getAttribute("PlanFreightCarrierCode");     // 運送業者(予定)

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId)); // 発生区分
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));  // 顧客ID
      cstmt.setString(i++, customerCode);                    // 顧客
      cstmt.setString(i++, instructions);                    // 摘要
      // 実績：入力の場合
      if (!XxcmnUtility.isBlankOrNull(resultFreightCarrierCode))
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(planFreightCarrierId)); // 運送業者ID
        cstmt.setString(i++, planFreightCarrierCode); // 運送業者
      // 実績：未入力、予定：入力の場合
      } else if ( XxcmnUtility.isBlankOrNull(resultFreightCarrierCode)
       && !XxcmnUtility.isBlankOrNull(freightCarrierCode)) 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(freightCarrierId)); // 運送業者ID
        cstmt.setString(i++, freightCarrierCode); // 運送業者
      // 実績：未入力、予定：入力の場合
      } else if (XxcmnUtility.isBlankOrNull(freightCarrierCode))
      {
        cstmt.setNull(i++, Types.INTEGER); // 運送業者ID
        cstmt.setNull(i++, Types.VARCHAR); // 運送業者
      }
      // 配送区分(実績)が未入力の場合
      if (XxcmnUtility.isBlankOrNull(resultShippingMethodCode)) 
      {
        cstmt.setString(i++, shippingMethodCode);   // 配送区分
      } else 
      {
        cstmt.setString(i++, dbShippingMethodCode); // 配送区分(DB)
      }
      // 出庫日(実績)が未入力の場合
      if (XxcmnUtility.isBlankOrNull(resultShippedDate)) 
      {
        cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate)); // 出庫日  
      } else 
      {
        cstmt.setNull(i++, Types.DATE); // 出庫日
      }
      // 入庫日(実績)が未入力の場合
      if (XxcmnUtility.isBlankOrNull(resultArrivalDate)) 
      {
        cstmt.setDate(i++, XxcmnUtility.dateValue(arrivalDate)); // 入庫日  
      } else 
      {
        cstmt.setNull(i++, Types.DATE); // 入庫日
      }
      cstmt.setString(i++, freightChargeClass);                   // 運賃区分
      cstmt.setString(i++, fixClass);                             // 金額確定
      cstmt.setString(i++, takebackClass);                        // 引取区分
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // 出庫倉庫ID
      cstmt.setString(i++, shipWhseCode);                         // 出庫倉庫
      cstmt.setString(i++, arrivalTimeFrom);                      // 着荷時間From
      cstmt.setString(i++, arrivalTimeTo);                        // 着荷時間To
      if (XxcmnUtility.isBlankOrNull(designatedItemId)) 
      {
        cstmt.setNull(i++, Types.NUMERIC); // 製造品目ID(INV)

      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(designatedItemId)); // 製造品目ID(INV)

      }
      cstmt.setString(i++, designatedItemCode);                   // 製造品目No
      cstmt.setDate(i++, XxcmnUtility.dateValue(designatedProdDate)); // 製造日
      cstmt.setString(i++, designatedBranchNo);                       // 製造番号
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumQuantity));   // 合計数量
      cstmt.setString(i++, XxcmnUtility.stringValue(smallQuantity));  // 小口個数
      cstmt.setString(i++, XxcmnUtility.stringValue(labelQuantity));  // ラベル枚数
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyWeight));   // 重量積載効率
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyCapacity)); // 容積積載効率
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedWeight));   // 基本重量
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedCapacity)); // 基本容積
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumWeight));     // 積載重量合計
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumCapacity));   // 積載容積合計
      cstmt.setString(i++, reqDeptCode);                          // 依頼部署
      cstmt.setString(i++, instDeptCode);                         // 指示部署
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // 取引先ID
      cstmt.setString(i++, vendorCode);                           // 取引先
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // 配送先ID
      cstmt.setString(i++, shipToCode);                           // 配送先
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // 受注ヘッダアドオンID
     
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHdr 

  /*****************************************************************************
   * 受注明細アドオンにデータを追加します。
   * @param hdrRow - ヘッダ行
   * @param insRow - 挿入対象行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void insertOrderLine(
    OARow hdrRow,
    OARow insRow
    ) throws OAException
  {
    String apiName      = "insertOrderLine";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_lines_all( ");
    sb.append("    order_line_id "              ); // 受注明細アドオンID
    sb.append("   ,order_header_id "            ); // 受注ヘッダアドオンID
    sb.append("   ,order_line_number "          ); // 明細番号
    sb.append("   ,request_no "                 ); // 依頼No
    sb.append("   ,shipping_inventory_item_id " ); // 出荷品目ID
    sb.append("   ,shipping_item_code "         ); // 出荷品目
    sb.append("   ,quantity "                   ); // 数量
    sb.append("   ,uom_code "                   ); // 単位
    sb.append("   ,based_request_quantity "     ); // 拠点依頼数量
    sb.append("   ,request_item_id "            ); // 依頼品目ID
    sb.append("   ,request_item_code "          ); // 依頼品目
    sb.append("   ,futai_code "                 ); // 付帯コード
    sb.append("   ,delete_flag "                ); // 削除フラグ
    sb.append("   ,line_description "           ); // 摘要
    sb.append("   ,unit_price "                 ); // 単価
    sb.append("   ,weight "                     ); // 重量
    sb.append("   ,capacity "                   ); // 容積
    sb.append("   ,created_by "                 ); // 作成者
    sb.append("   ,creation_date "              ); // 作成日
    sb.append("   ,last_updated_by "            ); // 最終更新者
    sb.append("   ,last_update_date "           ); // 最終更新日
    sb.append("   ,last_update_login) "         ); // 最終更新ログイン
    sb.append("  VALUES( ");
    sb.append("    xxwsh_order_lines_all_s1.NEXTVAL ");
    sb.append("   ,:1  ");
    sb.append("   ,:2  ");
    sb.append("   ,:3  ");
    sb.append("   ,:4  ");
    sb.append("   ,:5  ");
    sb.append("   ,TO_NUMBER(:6)  ");
    sb.append("   ,:7  ");
    sb.append("   ,:8  ");
    sb.append("   ,:9  ");
    sb.append("   ,:10 ");
    sb.append("   ,:11 ");
    sb.append("   ,'N' ");
    sb.append("   ,:12 ");
    sb.append("   ,TO_NUMBER(:13) ");
    sb.append("   ,TO_NUMBER(:14) ");
    sb.append("   ,TO_NUMBER(:15) ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.LOGIN_ID); ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number orderHeaderId   = (Number)hdrRow.getAttribute("OrderHeaderId");   // 受注ヘッダアドオンID
      Number orderLineNumber = (Number)insRow.getAttribute("OrderLineNumber"); // 明細番号
      String requestNo       = (String)hdrRow.getAttribute("RequestNo");       // 依頼No
      Number invItemId       = (Number)insRow.getAttribute("InvItemId");       // 出荷品目ID
      String itemNo          = (String)insRow.getAttribute("ItemNo");          // 出荷品目
      String instQuantity    = (String)insRow.getAttribute("InstQuantity");    // 数量
      String itemUm          = (String)insRow.getAttribute("ItemUm");          // 単位
      String reqQuantity     = (String)insRow.getAttribute("ReqQuantity");     // 拠点依頼数量
      Number whseInvItemId   = (Number)insRow.getAttribute("WhseInvItemId");   // 依頼品目ID
      String whseItemNo      = (String)insRow.getAttribute("WhseItemNo");      // 依頼品目
      String futaiCode       = (String)insRow.getAttribute("FutaiCode");       // 付帯コード
      String lineDescription = (String)insRow.getAttribute("LineDescription"); // 摘要
      String unitPrice        = XxcmnUtility.stringValue(
                                  (Number)insRow.getAttribute("UnitPriceNum")); // 単価
      String weight          = (String)insRow.getAttribute("Weight");          // 重量
      String capacity        = (String)insRow.getAttribute("Capacity");        // 容積
      
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));       // 受注ヘッダアドオンID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineNumber));     // 明細番号
      cstmt.setString(i++, requestNo);                               // 依頼No
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));           // 出荷品目ID
      cstmt.setString(i++, itemNo);                                  // 出荷品目
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity)); // 数量
      cstmt.setString(i++, itemUm);                                  // 単位
      cstmt.setString(i++, reqQuantity);                             // 拠点依頼数量
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));       // 依頼品目ID
      cstmt.setString(i++, whseItemNo);                              // 依頼品目
      cstmt.setString(i++, futaiCode);                               // 付帯コード
      cstmt.setString(i++, lineDescription);                         // 摘要
      cstmt.setString(i++, unitPrice);                               // 単価
      cstmt.setString(i++, weight);                                  // 重量
      cstmt.setString(i++, capacity);                                // 容積
     
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderLine 

  /*****************************************************************************
   * 受注明細アドオンのデータを更新します。
   * @param updRow - 更新対象行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void updateOrderLine(
    OARow updRow
    ) throws OAException
  {
    String apiName      = "updateOrderLine";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.shipping_inventory_item_id = :1 " ); // 出荷品目ID
    sb.append("        ,xola.shipping_item_code         = :2 " ); // 出荷品目
    sb.append("        ,xola.quantity                   = TO_NUMBER(:3) "); // 数量
    sb.append("        ,xola.uom_code                   = :4 " ); // 単位
    sb.append("        ,xola.based_request_quantity     = :5 " ); // 拠点依頼数量
    sb.append("        ,xola.request_item_id            = :6 " ); // 依頼品目ID
    sb.append("        ,xola.request_item_code          = :7 " ); // 依頼品目
    sb.append("        ,xola.futai_code                 = :8 " ); // 付帯コード
    sb.append("        ,xola.line_description           = :9 " ); // 摘要
    sb.append("        ,xola.unit_price                 = TO_NUMBER(:10) "); // 単価
    sb.append("        ,xola.weight                     = TO_NUMBER(:11) "); // 重量
    sb.append("        ,xola.capacity                   = TO_NUMBER(:12) "); // 容積
    sb.append("        ,xola.last_updated_by            = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xola.last_update_date           = SYSDATE "             ); // 最終更新日
    sb.append("        ,xola.last_update_login          = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xola.order_line_id = :13 ;"); // 受注明細アドオンID
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Number invItemId       = (Number)updRow.getAttribute("InvItemId");       // 出荷品目ID
      String itemNo          = (String)updRow.getAttribute("ItemNo");          // 出荷品目
      String instQuantity    = (String)updRow.getAttribute("InstQuantity");    // 数量
      String itemUm          = (String)updRow.getAttribute("ItemUm");          // 単位
      String reqQuantity     = (String)updRow.getAttribute("ReqQuantity");     // 拠点依頼数量
      Number whseInvItemId   = (Number)updRow.getAttribute("WhseInvItemId");   // 依頼品目ID
      String whseItemNo      = (String)updRow.getAttribute("WhseItemNo");      // 依頼品目
      String futaiCode       = (String)updRow.getAttribute("FutaiCode");       // 付帯コード
      String lineDescription = (String)updRow.getAttribute("LineDescription"); // 摘要
      Number orderLineId     = (Number)updRow.getAttribute("OrderLineId");     // 受注明細アドオンID
      String unitPrice        = XxcmnUtility.stringValue(
                                  (Number)updRow.getAttribute("UnitPriceNum")); // 単価
      String weight          = (String)updRow.getAttribute("Weight");          // 重量
      String capacity        = (String)updRow.getAttribute("Capacity");        // 容積
      
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));            // 出荷品目ID
      cstmt.setString(i++, itemNo);                                   // 出荷品目
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity));  // 数量
      cstmt.setString(i++, itemUm);                                   // 単位
      cstmt.setString(i++, reqQuantity);                              // 拠点依頼数量
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));        // 依頼品目ID
      cstmt.setString(i++, whseItemNo);                               // 依頼品目
      cstmt.setString(i++, futaiCode);                                // 付帯コード
      cstmt.setString(i++, lineDescription);                          // 摘要
      cstmt.setString(i++, unitPrice);                                // 単価
      cstmt.setString(i++, weight);                                   // 重量
      cstmt.setString(i++, capacity);                                 // 容積
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));          // 受注明細アドオンID
     
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine 

  /***************************************************************************
   * 依頼数を指示数へコピーするメソッドです。
   ***************************************************************************
   */
  public void doCopyReqQty()
  {
    // 支給指示作成明細情報VO取得
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    Row[] rows = vo.getAllRowsInRange();
    if ((rows != null) || (rows.length > 0)) 
    {
      OARow row       = null;
      String reqQty   = null;
      String dbReqQty = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i番目の行を取得
        row = (OARow)rows[i];
        reqQty   = (String)row.getAttribute("ReqQuantity");   // 依頼数
        dbReqQty = (String)row.getAttribute("DbReqQuantity"); // DB依頼数
        // 依頼数が変更された場合
// 2008-10-21 D.Nihei MOD START
//        if (!XxcmnUtility.chkCompareNumeric(3, reqQty, dbReqQty)) 
        if ( XxcmnUtility.isBlankOrNull(dbReqQty) 
         || !XxcmnUtility.chkCompareNumeric(3, reqQty, dbReqQty)) 
// 2008-10-21 D.Nihei MOD END
        {
          // 依頼数を指示数へコピー
          row.setAttribute("InstQuantity", reqQty);
        }
      }
    }
  } // doCopyReqQty

  /***************************************************************************
   * 行挿入処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void addRow(String exeType)
  {
    OARow maxRow = null;  
    Number maxOrderLineNumber = new Number(0); // 最大明細番号

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow   = (OARow)hdrVo.first();
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID

    // 支給指示作成明細情報VO取得
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // 最大の明細番号の取得
    maxRow = (OARow)vo.last();

    // レコードが存在する場合
    if (maxRow != null) 
    {
      maxOrderLineNumber = (Number)maxRow.getAttribute("OrderLineNumber");

    }
    // 行挿入
    OARow row = (OARow)vo.createRow();

    // Switcherの制御
    row.setAttribute("ItemSwitcher"   , "ItemNo");            // 品目制御
    // 起動タイプが「12：パッカー･外注工場用」の場合
    if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
    {
      row.setAttribute("FutaiSwitcher"  , "FutaiDisable");    // 付帯制御
    } else 
    {
      row.setAttribute("FutaiSwitcher"  , "FutaiCode");       // 付帯制御
    }
    row.setAttribute("ReqSwitcher"    , "ReqQuantity");       // 依頼数制御
    row.setAttribute("DescSwitcher"   , "LineDescription");   // 備考制御
    row.setAttribute("ShippedSwitcher", "ShippedIconDisable");// 出荷実績アイコン制御
    row.setAttribute("ShipToSwitcher" , "ShipToIconDisable"); // 入庫実績アイコン制御
    row.setAttribute("ReserveSwitcher", "ReserveIconDisable");// 仮引当アイコン制御
    row.setAttribute("DeleteSwitcher" , "DeleteEnable");      // 削除アイコン制御

    // デフォルト値の設定
    row.setAttribute("RecordType"     , XxcmnConstants.STRING_Y);    // レコードタイプ：新規
    row.setAttribute("FutaiCode"      , XxcmnConstants.STRING_ZERO); // 付帯：0
    row.setAttribute("OrderLineNumber", maxOrderLineNumber.add(1));  // 明細番号：最大の明細番号+1
    row.setAttribute("OrderHeaderId"  , orderHeaderId);              // 受注ヘッダアドオンID
    vo.last();
    vo.next();
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);
    // 変更に関する警告を設定
    super.setWarnAboutChanges();  

  } // addRow

  /***************************************************************************
   * 支給指示ヘッダ画面のコミット・再検索処理を行うメソッドです。
   * @param reqNo - 依頼No
   ***************************************************************************
   */
  public void doCommit(String reqNo)
  {
    // コミット発行
    XxpoUtility.commit(getOADBTransaction());

    // 支給依頼要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String exeType = (String)srow.getAttribute("ExeType");

    // ヘッダの再検索を行います。
    doSearchHdr(reqNo);

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // 支給指示作成ヘッダPVO
    XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
    // 1行もない場合、空行作成
    OARow prow = (OARow)pvo.first();

    // 更新時項目制御
    handleEventUpdHdr(exeType, prow, hdrRow);

    // 明細の再検索を行います。
    doSearchLine(exeType);

  } // doCommit

  /***************************************************************************
   * 確定処理のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkFix(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }

    // ステータスチェックを行います。
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    // ステータスが「入力中」以外の場合 
    if (!XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }
  } // chkFix

  /***************************************************************************
   * 受領処理のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkRcv(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));

    }

    // ステータスチェックを行います。
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    // ステータスが「入力完了」以外の場合 
    if (!XxpoConstants.PROV_STATUS_NRK.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }
// 2008-10-21 D.Nihei ADD START T_TE080_BPO_440 No14
    String autoCreatePoClass = (String)row.getAttribute("AutoCreatePoClass"); // 自動発注作成区分
    String purchaseCode      = (String)row.getAttribute("PurchaseCode");      // 仕入先コード
    String shipWhseCode      = (String)row.getAttribute("ShipWhseCode");      // 出庫倉庫
    // 出庫倉庫に費も付く仕入先コードが設定されているかチェックする。 
    if ("1".equals(autoCreatePoClass) && XxcmnUtility.isBlankOrNull(purchaseCode))
    {
      //トークンを生成します。
      MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM,
                                                 "出庫倉庫に紐付く仕入先") };
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShipWhseCode",
                            shipWhseCode,
                            XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10013,
                            tokens));
          
    }
// 2008-10-21 D.Nihei ADD END
// 2009-03-06 H.Iida ADD START 本番障害#1131
    // 仕入有償のみ明細全ての指示数が0かどうかチェックを行います
    if ("1".equals(autoCreatePoClass))
    {
      String requestNo = (String)row.getAttribute("RequestNo");    // 依頼No
      Number orderType = (Number)row.getAttribute("OrderTypeId");  // 発生区分
      if (chkRcvCntQuantity(getOADBTransaction(),
                            requestNo))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "OrderTypeId",
                              orderType,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10286));

      }
    }
// 2009-03-06 H.Iida ADD END
  } // chkRcv

  /***************************************************************************
   * 手動指示確定処理のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @param listFlag - 一覧フラグ true:一覧画面、false:ヘッダ画面
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkManualFix(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions,
    boolean listFlag
    ) throws OAException
  {
    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
    
    // ステータスチェックを行います。
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    // ステータスが「受領済」、「取消」以外の場合 
    if (!XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus)
     && !XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }

    // 通知ステータスチェックを行います。
    String notifStatus = (String)row.getAttribute("NotifStatus");    // 通知ステータス
    // ステータスが「受領」の場合
    if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // 通知ステータスが「未通知」、「再通知要」以外の場合
      if (!XxpoConstants.NOTIF_STATUS_MTT.equals(notifStatus)
       && !XxpoConstants.NOTIF_STATUS_STY.equals(notifStatus)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "NotifStatus",
                              notifStatus,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10124));

      }
      // 配車・引当済チェックを行います。
      String freightChargeClass = (String)row.getAttribute("FreightChargeClass"); // 運賃区分
      String shipToNo           = (String)row.getAttribute("ShipToNo");           // 配送No
      Number orderType          = (Number)row.getAttribute("OrderTypeId");        // 発生区分
      // 運賃区分が「対象」で、配送Noが設定されていない場合
      if (XxcmnConstants.OBJECT_ON.equals(freightChargeClass)
       && XxcmnUtility.isBlankOrNull(shipToNo)) 
      {
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROC_NAME,
                                                   XxpoConstants.TOKEN_NAME_CAREERS) };
        if (listFlag) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "OrderTypeId",
                                orderType,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));
        
        } else 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ShipToNo",
                                shipToNo,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));

        }
      }
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      // 引当済チェック
      if (!XxpoUtility.chkAllOrderReserved(getOADBTransaction(),
                                           orderHeaderId)) 
      {
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROC_NAME,
                                                   XxpoConstants.TOKEN_NAME_RESERVE) };
        if (listFlag) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "OrderTypeId",
                                orderType,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));
        
        } else 
        {
          exceptions.add( new OAException(
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));
        
        }
      }
    // ステータスが「取消」の場合
    } else if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      // 通知ステータスが「再通知要」以外の場合
      if (!XxpoConstants.NOTIF_STATUS_STY.equals(notifStatus)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "NotifStatus",
                              notifStatus,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10124));

      }
    }
  } // chkManualFix

  /***************************************************************************
   * 金額確定処理のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkAmountFix(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // 在庫会計期間クローズチェックを行います。
// 2009-01-20 v1.12 T.Yoshimoto Mod Start 本番#985
/*
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
*/
    Date arrivalDate = getUpdateArrivalDate(row); // 入庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  arrivalDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
// 2009-01-20 v1.12 T.Yoshimoto Mod End 本番#985

    // ステータスチェックを行います。
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    // ステータスが「出荷実績計上済」以外の場合 
    if (!XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }

    // 金額確定済チェックを行います。
    String fixClass  = (String)row.getAttribute("FixClass");    // 有償金額確定区分
    Number orderType = (Number)row.getAttribute("OrderTypeId"); // 発生区分
    // 有償金額確定区分が「確定」の場合
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "OrderTypeId",
                            orderType,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10125));

    }
  } // chkAmountFix

  /***************************************************************************
   * 価格設定処理のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @param listFlag - 一覧フラグ true:一覧画面、false:ヘッダ画面
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkPriceSet(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions,
    boolean listFlag
    ) throws OAException
  {
    // 在庫会計期間クローズチェックを行います。
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate"); // 入庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(), arrivalDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }

    // ステータスチェックを行います。
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    // ステータスが「取消」の場合
    if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }

    // 金額確定済チェックを行います。
    String fixClass  = (String)row.getAttribute("FixClass");    // 有償金額確定区分
    Number orderType = (Number)row.getAttribute("OrderTypeId"); // 発生区分
    // 有償金額確定区分が「確定」の場合
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      if (listFlag) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "OrderTypeId",
                              orderType,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10125));

        
      } else 
      {
        exceptions.add( new OAException(
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10125));
        
      }
    }
  } // chkPriceSet

  /***************************************************************************
   * 次へボタン押下時のチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkNext(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // 新規フラグ
    Object newFlag = row.getAttribute("NewFlag");    
    // 依頼部署
    Object reqDeptCode = row.getAttribute("ReqDeptCode");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(reqDeptCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ReqDeptCode",
                            reqDeptCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // 指示部署
    Object instDeptCode = row.getAttribute("InstDeptCode");
    // 更新時のみ必須チェック
    if (XxcmnConstants.STRING_N.equals(newFlag)
     && XxcmnUtility.isBlankOrNull(instDeptCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "InstDeptCode",
                            instDeptCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // 取引先
    Object vendorCode = row.getAttribute("VendorCode");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(vendorCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "VendorCode",
                            vendorCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // 配送先
    Object shipToCode = row.getAttribute("ShipToCode");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(shipToCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShipToCode",
                            shipToCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
    }

    // 出庫倉庫
    Object shipWhseCode = row.getAttribute("ShipWhseCode");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(shipWhseCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShipWhseCode",
                            shipWhseCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
    }

    // 運送業者
    Object freightCarrierCode = row.getAttribute("FreightCarrierCode");
    String freightChargeClass = (String)row.getAttribute("FreightChargeClass"); // 運賃区分
    // 更新時且つ運賃区分が「対象」の場合のみ必須チェック
    if (XxcmnConstants.STRING_N.equals(newFlag)
     && XxcmnConstants.OBJECT_ON.equals(freightChargeClass)
     && XxcmnUtility.isBlankOrNull(freightCarrierCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "FreightCarrierCode",
                            freightCarrierCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // 出庫日
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // 更新時のみ必須チェック
    if (XxcmnConstants.STRING_N.equals(newFlag)
     && XxcmnUtility.isBlankOrNull(shippedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // 入庫日
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    // 出庫日が入力されている場合
    } else if (!XxcmnUtility.isBlankOrNull(shippedDate))
    {
// 2008-10-21 D.Nihei Add START
      // 実績日(出庫日、入庫日)を取得します。
      Date resultShippedDate = (Date)row.getAttribute("ResultShippedDate"); // 出庫日
      Date resultArrivalDate = (Date)row.getAttribute("ResultArrivalDate"); // 入庫日
      // 実績日が両方入力されている場合または両方入力されていない場合
      if ( XxcmnUtility.isBlankOrNull(resultShippedDate) 
       &&  XxcmnUtility.isBlankOrNull(resultArrivalDate))
      {
// 2008-10-21 D.Nihei Add END
        // 出庫日＞入庫日の場合
        if (XxcmnUtility.chkCompareDate(1, shippedDate, arrivalDate)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ShippedDate",
                                shippedDate,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10118));

        }
// 2008-10-21 D.Nihei Add START
      }
// 2008-10-21 D.Nihei Add END
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkNext

  /***************************************************************************
   * 適用処理のチェックを行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkOrderLine(String exeType) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List

    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

// 2009-01-22 v1.13 T.Yoshimoto Add Start 本番#985
    // 金額確定済チェックを行います。
    String fixClass  = (String)hdrRow.getAttribute("FixClass");  // 有償金額確定区分
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // 出庫日

    // 有償金額確定区分が「確定」でない場合、出庫日ベースでチェック
    if (XxpoConstants.FIX_CLASS_OFF.equals(fixClass))
    {
// 2009-01-22 v1.13 T.Yoshimoto Add End 本番#985

    // 在庫会計期間クローズチェックを行います。
// 2009-01-22 v1.13 T.Yoshimoto Del Start 本番#985
    //Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // 出庫日
// 2009-01-22 v1.13 T.Yoshimoto Del End 本番#985
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            hdrVo.getName(),
                            hdrRow.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));

    }
// 2009-01-22 v1.13 T.Yoshimoto Add Start 本番#985
    // 有償金額確定区分が「確定」の場合、入庫日ベースでチェック
    } else
    {
      // 在庫会計期間クローズチェックを行います。
      Date arrivalDate = getUpdateArrivalDate(hdrRow);            // 入庫日
      if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                    arrivalDate))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              hdrVo.getName(),
                              hdrRow.getKey(),
                              "ArrivalDate",
                              arrivalDate,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10119));
      }
    }
// 2009-01-22 v1.13 T.Yoshimoto Add End 本番#985

    // 単価導出可否を判断します。
    boolean priceFlag = false;
    Date arrivalDate  = (Date)hdrRow.getAttribute("ArrivalDate"); // 入庫日
    Object vendorCode = hdrRow.getAttribute("VendorCode");        // 取引先
    // 入庫日・取引先の場合
    if (!XxcmnUtility.isEquals(arrivalDate, hdrRow.getAttribute("DbArrivalDate"))
     || !XxcmnUtility.isEquals(vendorCode,  hdrRow.getAttribute("DbVendorCode")) ) 
    {
      priceFlag = true;  

    }
    //支給指示要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId"); // 代表価格表      
    String listIdVendor    = (String)hdrRow.getAttribute("PriceList");    // 取引先価格表ID
    
    // 処理対象を取得します。
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // 更新行取得
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((updRows != null) || (updRows.length > 0)) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++)
      {
        // i番目の行を取得
        updRow = (OARow)updRows[i];

        // 品目が変更された場合
        if (!XxcmnUtility.isEquals(updRow.getAttribute("ItemId"), 
                                   updRow.getAttribute("DbItemId"))) 
        {
          priceFlag = true;   
        }
        
        // 更新チェック処理
        if (!chkOrderLineUpd(hdrRow, vo, updRow, exceptions))
        {
          // 明細導出処理
          getLineData(vo,
                      updRow,
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
                      shippedDate,
// 2008-10-07 H.Itou Add End
                      arrivalDate,
                      listIdRepresent,
                      listIdVendor,
                      priceFlag,
                      exceptions);
        }
      }
    }
    // 挿入行取得
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0)) 
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++)
      {
        // i番目の行を取得
        insRow = (OARow)insRows[i];

        // 挿入チェック処理
        if (!chkOrderLineIns(hdrRow, vo, insRow, exceptions, exeType))
        {
          if (!(XxcmnUtility.isBlankOrNull(insRow.getAttribute("ItemNo"))
           && XxcmnUtility.isBlankOrNull(insRow.getAttribute("ReqQuantity"))
           && XxcmnUtility.isBlankOrNull(insRow.getAttribute("LineDescription")))) 
          {
            // 単価導出フラグをtrueにする
            priceFlag = true;  
            // 明細導出処理
            getLineData(vo,
                        insRow,
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
                        shippedDate,
// 2008-10-07 H.Itou Add End
                        arrivalDate,
                        listIdRepresent,
                        listIdVendor,
                        priceFlag,
                        exceptions);
          }
        }
      }
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkOrderLine

  /***************************************************************************
   * 適用処理のチェックを行うメソッドです。(更新用)
   * @param hdrRow - ヘッダ行オブジェクト
   * @param vo     - ビューオブジェクト
   * @param row    - 明細行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @return boolean - エラーフラグ true:エラー有
   *                              false:エラー無
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkOrderLineUpd(
    OARow hdrRow,
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    boolean errFlag = false; // エラー発生フラグ

    // 情報を取得
    Object orderLineNum = row.getAttribute("OrderLineNumber"); // 明細番号
    Object itemNo       = row.getAttribute("ItemNo");          // 品目コード
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(itemNo)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ItemNo",
                            itemNo,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else
    {
      // 仕入有償品目チェック
      String lotCtl            = (String)row.getAttribute("LotCtl");               // ロット管理区分
      String autoCreatePoClass = (String)hdrRow.getAttribute("AutoCreatePoClass"); // 自動発注作成区分
      // 自動発注作成区分が「1：自動」で、「ロット管理対象」の場合
      if ("1".equals(autoCreatePoClass) && XxpoConstants.LOT_CTL_1.equals(lotCtl)) 
      {
        // 仕入有償品目チェックエラー 
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ItemNo",
                              itemNo,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10031));
        errFlag = true;

      } else
      {
        // チェック用全行取得
        Row[] chkRows = vo.getAllRowsInRange();
        // 更新行の明細件数が1件しかない場合
        if ((chkRows != null) || (chkRows.length >0)) 
        {
          OARow chkRow = null;
          for (int i = 0; i < chkRows.length; i++)
          {
            // i番目の行を取得
            chkRow = (OARow)chkRows[i];
            // 品目重複チェック(他のレコードと品目が同一の場合)
            if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))
              && XxcmnUtility.isEquals(itemNo      , chkRow.getAttribute("ItemNo"))) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ItemNo",
                                    itemNo,
                                    XxcmnConstants.APPL_XXPO, 
                                    XxpoConstants.XXPO10151));
              errFlag = true;
              break;
            }
          }
        }
      }
    }

    Object futaiCode = row.getAttribute("FutaiCode");       // 付帯コード
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(futaiCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "FutaiCode",
                            futaiCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

      errFlag = true;

    }

    Object reqQuantity = row.getAttribute("ReqQuantity");       // 依頼数量
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(reqQuantity)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ReqQuantity",
                            reqQuantity,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else 
    {
      // 数値チェック
      if (!XxcmnUtility.chkNumeric(reqQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ReqQuantity",
                              reqQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
        errFlag = true;

      } else
      {
        // 数量チェック
        if (!XxcmnUtility.chkCompareNumeric(2, reqQuantity, XxcmnConstants.STRING_ZERO)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ReqQuantity",
                                reqQuantity,
                                XxcmnConstants.APPL_XXPO,         
                                XxpoConstants.XXPO10153));
          errFlag = true;

        }
      }
    }
    return errFlag;
    
  } // chkOrderLineUpd

  /***************************************************************************
   * 適用処理のチェックを行うメソッドです。(挿入用)
   * @param hdrRow - ヘッダ行オブジェクト
   * @param vo     - ビューオブジェクト
   * @param row    - 明細行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @param exeType - 起動タイプ
   * @return boolean - エラーフラグ true:エラー有
   *                              false:エラー無
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkOrderLineIns(
    OARow hdrRow,
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions,
    String exeType
    ) throws OAException
  {
    boolean errFlag = false; // エラー発生フラグ

    // 情報を取得
    Object orderLineNum = row.getAttribute("OrderLineNumber"); // 明細番号
    Object itemNo       = row.getAttribute("ItemNo");          // 品目コード
    Object futaiCode    = row.getAttribute("FutaiCode");       // 付帯コード
    Object reqQuantity  = row.getAttribute("ReqQuantity");     // 依頼数量
    Object description  = row.getAttribute("LineDescription"); // 備考

    // 全て入力されていなければチェックしない
    if (XxcmnUtility.isBlankOrNull(itemNo)
     && (XxcmnUtility.isBlankOrNull(futaiCode) || XxpoConstants.EXE_TYPE_12.equals(exeType))
     && XxcmnUtility.isBlankOrNull(reqQuantity)
     && XxcmnUtility.isBlankOrNull(description)) 
    {
      return errFlag;  

    }
    
    // 必須チェック(品目)
    if (XxcmnUtility.isBlankOrNull(itemNo)
     && ((!XxcmnUtility.isBlankOrNull(futaiCode) && !XxpoConstants.EXE_TYPE_12.equals(exeType))
      || !XxcmnUtility.isBlankOrNull(reqQuantity)
      || !XxcmnUtility.isBlankOrNull(description))) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ItemNo",
                            itemNo,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else
    {
      // 仕入有償品目チェック
      String lotCtl            = (String)row.getAttribute("LotCtl");               // ロット管理区分
      String autoCreatePoClass = (String)hdrRow.getAttribute("AutoCreatePoClass"); // 自動発注作成区分
      // 自動発注作成区分が「1：自動」で、「ロット管理対象」の場合
      if ("1".equals(autoCreatePoClass) && XxpoConstants.LOT_CTL_1.equals(lotCtl)) 
      {
        // 仕入有償品目チェックエラー 
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ItemNo",
                              itemNo,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10031));
        errFlag = true;

      } else
      {
        // チェック用全行取得
        Row[] chkRows = vo.getAllRowsInRange();
        // 更新行の明細件数が1件しかない場合
        if ((chkRows != null) || (chkRows.length >0)) 
        {
          OARow chkRow = null;
          for (int i = 0; i < chkRows.length; i++)
          {
            // i番目の行を取得
            chkRow = (OARow)chkRows[i];
            // 品目重複チェック(他のレコードと品目が同一の場合)
            if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))
              && XxcmnUtility.isEquals(itemNo      , chkRow.getAttribute("ItemNo"))) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ItemNo",
                                    itemNo,
                                    XxcmnConstants.APPL_XXPO, 
                                    XxpoConstants.XXPO10151));
              errFlag = true;

              break;

            }
          }
        }
      }
    }

    // 必須チェック(付帯)
    if (XxcmnUtility.isBlankOrNull(futaiCode)
     && (!XxcmnUtility.isBlankOrNull(itemNo)
      || !XxcmnUtility.isBlankOrNull(reqQuantity)
      || !XxcmnUtility.isBlankOrNull(description))) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "FutaiCode",
                            futaiCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    }

    // 必須チェック(依頼数)
    if (XxcmnUtility.isBlankOrNull(reqQuantity)
     && (!XxcmnUtility.isBlankOrNull(itemNo)
      || (!XxcmnUtility.isBlankOrNull(futaiCode) && !XxpoConstants.EXE_TYPE_12.equals(exeType))
      || !XxcmnUtility.isBlankOrNull(description))) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ReqQuantity",
                            reqQuantity,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else 
    {
      // 数値チェック
      if (!XxcmnUtility.chkNumeric(reqQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ReqQuantity",
                              reqQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
        errFlag = true;

      } else
      {

        // 数量チェック
        if (!XxcmnUtility.chkCompareNumeric(2, reqQuantity, XxcmnConstants.STRING_ZERO)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ReqQuantity",
                                reqQuantity,
                                XxcmnConstants.APPL_XXPO,         
                                XxpoConstants.XXPO10153));
          errFlag = true;
        }
      }
    }
    return errFlag;

  } // chkOrderLineIns

  /***************************************************************************
   * 削除処理のチェックを行うメソッドです。
   * @param vo     - ビューオブジェクト
   * @param hdrRow - ヘッダ行オブジェクト
   * @param row    - 明細行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkOrderLineDel(
    OAViewObjectImpl vo,
    OARow hdrRow,
    OARow row
    ) throws OAException
  {
    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      throw new OAException(
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10119);

    }
  } // chkOrderLineDel

  /***************************************************************************
   * ロック・排他処理を行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkLockAndExclusive(
    OAViewObjectImpl vo,
    OARow row
    ) throws OAException
  {
    // ロックを取得します。
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    Number orderType     = (Number)row.getAttribute("OrderTypeId");   // 発生区分
    if (!XxpoUtility.getXxwshOrderLock(getOADBTransaction(), orderHeaderId)) 
    {
      XxpoUtility.rollBack(getOADBTransaction());
      // ロックエラーメッセージ
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "OrderTypeId",
                  orderType,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10138);

    }
    // 排他チェックを行います。
    String xohaLastUpdateDate = (String)row.getAttribute("XohaLastUpdateDate"); // 最終更新日（受注ヘッダ）
    String xolaLastUpdateDate = (String)row.getAttribute("XolaLastUpdateDate"); // 最終更新日（受注明細）
    if (!XxpoUtility.chkExclusiveXxwshOrder(getOADBTransaction(),
                                            orderHeaderId,
                                            xohaLastUpdateDate,
                                            xolaLastUpdateDate)) 
    {
      XxpoUtility.rollBack(getOADBTransaction());
      // 排他エラーメッセージ
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "OrderTypeId",
                  orderType,
                  XxcmnConstants.APPL_XXCMN, 
                  XxcmnConstants.XXCMN10147);
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * ヘッダ項目の導出処理を行うメソッドです。
   * @param hdrVo  - ヘッダビューオブジェクト
   * @param hdrRow - ヘッダ行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getHdrData(
    OAViewObjectImpl hdrVo,
    OARow hdrRow
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List

    // 各種情報を取得します。
    Date arrivalDate     = (Date)hdrRow.getAttribute("ArrivalDate");          // 入庫日 
    Date shippedDate     = (Date)hdrRow.getAttribute("ShippedDate");          // 出庫日
    String shipToCode    = (String)hdrRow.getAttribute("ShipToCode");         // 配送先
    String shipWhseCode  = (String)hdrRow.getAttribute("ShipWhseCode");       // 出庫倉庫
    String freightCode   = (String)hdrRow.getAttribute("FreightCarrierCode"); // 運送業者
    String frequentMover = (String)hdrRow.getAttribute("FrequentMover");      // 代表運送会社
    String freightClass  = (String)hdrRow.getAttribute("FreightChargeClass"); // 運賃区分
    Number orderTypeId   = (Number)hdrRow.getAttribute("OrderTypeId");        // 発生区分
    String weightCapacityClass = (String)hdrRow.getAttribute("WeightCapacityClass"); // 重量容積区分
    String autoCreatePoClass   = (String)hdrRow.getAttribute("AutoCreatePoClass");   // 自動発注作成区分

    // 指示部署が未入力の場合
    if (XxcmnUtility.isBlankOrNull(hdrRow.getAttribute("InstDeptCode"))) 
    {
      // 依頼部署を指示部署へコピー
      hdrRow.setAttribute("InstDeptCode", hdrRow.getAttribute("ReqDeptCode"));  
      hdrRow.setAttribute("InstDeptName", hdrRow.getAttribute("ReqDeptName"));  
    }
    // 発生区分から自動発注作成区分を取得
    autoCreatePoClass = XxpoUtility.getAutoCreatePoClass(
                          getOADBTransaction(),
                          orderTypeId);
    // 自動発注作成区分を格納
    hdrRow.setAttribute("AutoCreatePoClass", autoCreatePoClass);

    // 出庫日が入力されていない場合
    if (XxcmnUtility.isBlankOrNull(shippedDate)) 
    {
      shippedDate = XxpoUtility.getOprtnDay(
                      getOADBTransaction(),
                      XxcmnUtility.getDate(arrivalDate, -1),
                      shipWhseCode,
                      null,
                      0); 
      // 導出されなかった場合
      if (XxcmnUtility.isBlankOrNull(shippedDate)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              hdrVo.getName(),
                              hdrRow.getKey(),
                              "ShippedDate",
                              shippedDate,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10002));

      } else
      {
        // 出庫日にセット
        hdrRow.setAttribute("ShippedDate", shippedDate);

      }
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // 運賃区分が「対象」、且つ運送業者が入力されていない場合
    if (XxcmnConstants.STRING_ONE.equals(freightClass) && XxcmnUtility.isBlankOrNull(freightCode)) 
    {
      if (XxcmnUtility.isBlankOrNull(frequentMover)) 
      {
        exceptions.add( new OAException(
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10117));
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              hdrVo.getName(),
                              hdrRow.getKey(),
                              "FreightCarrierCode",
                              freightCode,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10002));

      } else 
      {
        Number freightId   = null;
        String freightname = null;
        // 代表運送会社を元に算出する。
        HashMap paramsRet = XxpoUtility.getfreightData(
                              getOADBTransaction(),
                              frequentMover,
                              freightId,
                              freightCode,
                              freightname,
                              shippedDate); 

        if (XxcmnUtility.isBlankOrNull(paramsRet.get("freightCode"))) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                hdrVo.getName(),
                                hdrRow.getKey(),
                                "FreightCarrierCode",
                                paramsRet.get("freightCode"),
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10002));

        } else 
        {
          // 運送業者にセット
          hdrRow.setAttribute("FreightCarrierId"  , paramsRet.get("freightId"));
          hdrRow.setAttribute("FreightCarrierCode", paramsRet.get("freightCode"));
          hdrRow.setAttribute("FreightCarrierName", paramsRet.get("freightName"));

        }
      }
      // エラーがあった場合エラーをスローします。
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
  } // getHdrData

  /***************************************************************************
   * 明細項目の導出処理を行うメソッドです。
   * @param vo  - 明細ビューオブジェクト
   * @param row - 明細行オブジェクト
   * @param shippedDate     - 出庫日
   * @param arrivalDate     - 入庫日
   * @param listIdRepresent - 代表価格表ID
   * @param listIdVendor    - 取引先価格表ID
   * @param priceFlag       - 単価導出可否フラグ true:実行、false:実行しない
   * @param exceptions      - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getLineData(
    OAViewObjectImpl vo,
    OARow row,
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
    Date shippedDate,
// 2008-10-07 H.Itou Add End
    Date arrivalDate,
    String listIdRepresent,
    String listIdVendor,
    boolean priceFlag,
    ArrayList exceptions
    ) throws OAException
  {
    Number invItemId   = (Number)row.getAttribute("InvItemId");   // INV品目ID
    String itemNo      = (String)row.getAttribute("ItemNo");      // 品目No
    String reqQuantity = (String)row.getAttribute("ReqQuantity"); // 依頼数
    // 単価導出フラグがtrue、または品目が変更された場合
    if (priceFlag) 
    {
      // 単価導出処理  
      Number unitPrice = XxpoUtility.getUnitPrice(
                           getOADBTransaction(),
                           invItemId,
                           listIdVendor,
                           listIdRepresent,
                           arrivalDate,
                           itemNo);

      // 取得できなかった場合
      if (XxcmnUtility.isBlankOrNull(unitPrice)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ItemNo",
                              itemNo,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10201));

      } else
      {
        row.setAttribute("UnitPriceNum", unitPrice);

      }
    }
    // 合計重量・合計容積の導出
    HashMap retMap = XxpoUtility.calcTotalValue(
                       getOADBTransaction(),
                       itemNo,
                       XxcmnUtility.commaRemoval(reqQuantity),
// 2008-10-07 H.Itou Add Start 統合テスト指摘240
                       shippedDate
// 2008-10-07 H.Itou Add End
                       );
    String retCode = (String)retMap.get("retCode");
    // 戻り値がエラーの場合
    if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
    {
       MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                  XxpoConstants.TOKEN_NAME_CALC_ERR) };
       exceptions.add( new OAAttrValException(
                             OAAttrValException.TYP_VIEW_OBJECT,          
                             vo.getName(),
                             row.getKey(),
                             "ItemNo",
                             itemNo,
                             XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN05002,
                             tokens));

    } else
    {
      // 重量、容積にセット
      row.setAttribute("Weight",   (String)retMap.get("sumWeight"));
      row.setAttribute("Capacity", (String)retMap.get("sumCapacity"));

    }
  } // getLineData

  /***************************************************************************
   * 配車関連情報をセットするメソッドです。
   * @param hdrRow - ヘッダ行オブジェクト
   ***************************************************************************
   */
  public void setCarriersData(OARow hdrRow)
  {
    /****************************
     * ヘッダ各種情報取得
     ****************************/
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");      // 受注ヘッダアドオンID
    String freightClass  = (String)hdrRow.getAttribute("FreightChargeClass"); // 運賃区分

    /****************************
     * 配車関連情報導出
     ****************************/
    HashMap retParams = XxpoUtility.getCarriersData(
                          getOADBTransaction(),
                          orderHeaderId);
    /****************************
     * 各項目をセット
     ****************************/
    // 運賃区分が「対象」の場合
    if (XxcmnUtility.isEquals(freightClass, XxcmnConstants.OBJECT_ON)) 
    {
      hdrRow.setAttribute("SmallQuantity", retParams.get("smallQuantity"));  // 小口個数
      hdrRow.setAttribute("LabelQuantity", retParams.get("labelQuantity"));  // ラベル枚数

    } else 
    {
      hdrRow.setAttribute("SmallQuantity", null);  // 小口個数
      hdrRow.setAttribute("LabelQuantity", null);  // ラベル枚数
      
    }
    hdrRow.setAttribute("SumQuantity",   retParams.get("sumQuantity"));    // 合計数量
    hdrRow.setAttribute("SumWeight",     retParams.get("sumWeight"));      // 合計重量
    hdrRow.setAttribute("SumCapacity",   retParams.get("sumCapacity"));    // 合計容積

  } // setCarriersData

  /***************************************************************************
   * 支給指示作成ヘッダ画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param baseReqNo   - 元依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void initializeCopy(
    String exeType,
    String baseReqNo
    ) throws OAException
  {
    // 支給依頼要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0)
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey",  new Number(1));
      srow.setAttribute("ExeType", exeType);
      //プロファイルから代表価格表ID取得
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // 代表価格表が取得できない場合
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      srow.setAttribute("RepPriceListId", repPriceListId);
    }
    // 支給指示作成ヘッダPVO
    XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
    // 1行もない場合、空行作成
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));

    } else
    {
      prow = (OARow)pvo.first();
      // 初期化
      handleEventAllOnHdr(prow);

    }

    OARow hdrRow  = null;
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    if (hdrVo.getFetchedRowCount() == 0)
    {
      hdrVo.setMaxFetchSize(0);
      hdrVo.executeQuery();
      hdrVo.insertRow(hdrVo.createRow());
      hdrRow = (OARow)hdrVo.first();
      hdrRow.setNewRowState(OARow.STATUS_INITIALIZED);
    } else
    {
      hdrRow = (OARow)hdrVo.first();
    }

    // キーの設定
    hdrRow.setAttribute("OrderHeaderId", new Number(-1));
    // デフォルト値の設定
    hdrRow.setAttribute("NewFlag",             XxcmnConstants.STRING_Y);              // 新規フラグ
    hdrRow.setAttribute("TransStatus",         XxpoConstants.PROV_STATUS_NRT);        // ステータス
    hdrRow.setAttribute("NotifStatus",         XxpoConstants.NOTIF_STATUS_MTT);       // 通知ステータス
    hdrRow.setAttribute("RcvClass",            XxpoConstants.RCV_CLASS_OFF);          // 指示受領
    hdrRow.setAttribute("FixClass",            XxpoConstants.FIX_CLASS_OFF);          // 金額確定

    // 支給指示作成コピーヘッダVO取得
    XxpoProvCopyHeaderVOImpl copyHdrVo = getXxpoProvCopyHeaderVO1();
    copyHdrVo.initQuery(baseReqNo);
    copyHdrVo.first();
    // コピー元の対象データを取得できない場合エラー
    if ((copyHdrVo == null)  || (copyHdrVo.getFetchedRowCount() == 0)) 
    {
      // 参照のみ
      handleEventAllOffHdr(prow);
      prow.setAttribute("NextBtnReject", Boolean.TRUE); // 次へボタン
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);
    }

    OARow copyHdrRow = (OARow)copyHdrVo.first(); 
    Number baseOrderHdrId = (Number)copyHdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    // 支給指示作成コピー明細VO取得
    XxpoProvCopyLineVOImpl copyLineVo = getXxpoProvCopyLineVO1();
    copyLineVo.initQuery(exeType, baseOrderHdrId);
    copyLineVo.first();
    // コピー元の対象データを取得できない場合エラー
    if ((copyLineVo == null) || (copyLineVo.getFetchedRowCount() == 0)) 
    {
      // 参照のみ
      handleEventAllOffHdr(prow);
      prow.setAttribute("NextBtnReject", Boolean.TRUE); // 次へボタン
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);

    }

    // ヘッダコピー処理実施
    hdrRow.setAttribute("AutoCreatePoClass",   copyHdrRow.getAttribute("AutoCreatePoClass"));  // 自動発注作成区分
    hdrRow.setAttribute("OrderTypeId",         copyHdrRow.getAttribute("OrderTypeId"));        // 発生区分
    hdrRow.setAttribute("OrderTypeName",       copyHdrRow.getAttribute("OrderTypeName"));      // 発生区分名
    hdrRow.setAttribute("WeightCapacityClass", copyHdrRow.getAttribute("WeightCapacityClass")); // 重量容積区分
    hdrRow.setAttribute("BaseRequestNo",       copyHdrRow.getAttribute("RequestNo"));          // 元依頼No
    hdrRow.setAttribute("ReqDeptCode",         copyHdrRow.getAttribute("ReqDeptCode"));        // 依頼部署
    hdrRow.setAttribute("ReqDeptName",         copyHdrRow.getAttribute("ReqDeptName"));        // 依頼部署名
    hdrRow.setAttribute("InstDeptCode",        copyHdrRow.getAttribute("InstDeptCode"));       // 指示部署
    hdrRow.setAttribute("InstDeptName",        copyHdrRow.getAttribute("InstDeptName"));       // 指示部署名
    hdrRow.setAttribute("VendorId",            copyHdrRow.getAttribute("VendorId"));           // 取引先ID
    hdrRow.setAttribute("VendorCode",          copyHdrRow.getAttribute("VendorCode"));         // 取引先コード
    hdrRow.setAttribute("VendorName",          copyHdrRow.getAttribute("VendorName"));         // 取引先名
    hdrRow.setAttribute("ShipToId",            copyHdrRow.getAttribute("ShipToId"));           // 配送先ID
    hdrRow.setAttribute("ShipToCode",          copyHdrRow.getAttribute("ShipToCode"));         // 配送先コード
    hdrRow.setAttribute("ShipToName",          copyHdrRow.getAttribute("ShipToName"));         // 配送先名
    hdrRow.setAttribute("ShipWhseId",          copyHdrRow.getAttribute("ShipWhseId"));         // 出庫倉庫ID
    hdrRow.setAttribute("ShipWhseCode",        copyHdrRow.getAttribute("ShipWhseCode"));       // 出庫倉庫コード
    hdrRow.setAttribute("ShipWhseName",        copyHdrRow.getAttribute("ShipWhseName"));       // 出庫倉庫名
    hdrRow.setAttribute("FreightCarrierId",    copyHdrRow.getAttribute("FreightCarrierId"));   // 運送業者ID
    hdrRow.setAttribute("FreightCarrierCode",  copyHdrRow.getAttribute("FreightCarrierCode")); // 運送業者コード
    hdrRow.setAttribute("FreightCarrierName",  copyHdrRow.getAttribute("FreightCarrierName")); // 運送業者名
    hdrRow.setAttribute("ShippedDate",         copyHdrRow.getAttribute("ShippedDate"));        // 出庫日
    hdrRow.setAttribute("ArrivalDate",         copyHdrRow.getAttribute("ArrivalDate"));        // 入庫日
    hdrRow.setAttribute("ArrivalTimeFrom",     copyHdrRow.getAttribute("ArrivalTimeFrom"));    // 着荷時間From
    hdrRow.setAttribute("ArrivalTimeFromName", copyHdrRow.getAttribute("ArrivalTimeFromName"));// 着荷時間From名
    hdrRow.setAttribute("ArrivalTimeTo",       copyHdrRow.getAttribute("ArrivalTimeTo"));      // 着荷時間To
    hdrRow.setAttribute("ArrivalTimeToName",   copyHdrRow.getAttribute("ArrivalTimeToName"));  // 着荷時間To名
    hdrRow.setAttribute("FreightChargeClass",  copyHdrRow.getAttribute("FreightChargeClass")); // 運賃区分
    hdrRow.setAttribute("TakebackClass",       copyHdrRow.getAttribute("TakebackClass"));      // 引取区分
    hdrRow.setAttribute("DesignatedProdDate",  copyHdrRow.getAttribute("DesignatedProdDate")); // 製造日
    hdrRow.setAttribute("DesignatedItemCode",  copyHdrRow.getAttribute("DesignatedItemCode")); // 製造品目コード
    hdrRow.setAttribute("DesignatedItemName",  copyHdrRow.getAttribute("DesignatedItemName")); // 製造品目名
    hdrRow.setAttribute("DesignatedBranchNo",  copyHdrRow.getAttribute("DesignatedBranchNo")); // 製造番号
    hdrRow.setAttribute("ShippingInstructions", copyHdrRow.getAttribute("ShippingInstructions")); // 摘要
    hdrRow.setAttribute("DesignatedItemId",    copyHdrRow.getAttribute("DesignatedItemId"));   // 製造品目ID
    hdrRow.setAttribute("FrequentMover",       copyHdrRow.getAttribute("FrequentMover"));      // 代表運送会社
    hdrRow.setAttribute("CustomerId",          copyHdrRow.getAttribute("CustomerId"));         // 顧客ID
    hdrRow.setAttribute("CustomerCode",        copyHdrRow.getAttribute("CustomerCode"));       // 顧客コード
    hdrRow.setAttribute("PriceList",           copyHdrRow.getAttribute("PriceList"));          // 価格表

    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
    // 支給指示作成明細VO取得
    XxpoProvisionInstMakeLineVOImpl lineVo = getXxpoProvisionInstMakeLineVO1();
    // 検索を実行します。
    lineVo.initQuery(exeType, orderHeaderId);
    copyRows(copyLineVo, lineVo);
    
    // 新規時項目制御
    handleEventInsHdr(exeType, prow, hdrRow);

  } // initializeCopy
  
  /***************************************************************************
   * コピー処理のチェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String chkCopy() throws OAException
  {
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // 選択されたレコードを取得
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    // 複数選択チェックを行います。
    chkManyChoice(rows);
    // 1番目のレコードを選択
    OARow row = (OARow)rows[0];
    // ステータスチェックを行います。
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    // ステータスが「入力中」、「入力完了」、「受領済」以外の場合 
    if (!XxpoConstants.PROV_STATUS_NRT.equals(transStatus)
     && !XxpoConstants.PROV_STATUS_NRK.equals(transStatus)
     && !XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus)) 
    {
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "TransStatus",
                  transStatus,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10145);
          
    }
  
    return (String)row.getAttribute("RequestNo");
  } // chkCopy

  /***************************************************************************
   * 複数選択チェックを行うメソッドです。
   * @param rows - 行オブジェクト配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkManyChoice(
    Row[] rows
    ) throws OAException
  {
    // 複数選択チェックを行います。
    if (rows.length != 1)
    {
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10214);
    }
  } // chkManyChoice

  /***************************************************************************
   * 明細行コピー処理を行うメソッドです。
   * @param orgVo  - コピー元VO
   * @param destVo - コピー先VO
   ***************************************************************************
   */
  public static void copyRows(OAViewObjectImpl orgVo, OAViewObjectImpl destVo)
  {
    // どちらかのVOがnullの場合は処理終了
    if (orgVo == null || destVo == null)
    {
      return;
    }

    // コピー元のVOの属性を取得
    AttributeDef[] attrDefs = orgVo.getAttributeDefs();
    int attrCount = (attrDefs == null) ? 0 : attrDefs.length;
    // 属性が取得できない場合は処理終了
    if (attrCount == 0)
    {
      return;
    }
    // コピー用イテレータを取得します。
    RowSetIterator copyIter = orgVo.findRowSetIterator("copyIter");
    // コピー用イテレータがnullの場合
    if (copyIter == null)
    {
      // イテレータを作成します。
      copyIter = orgVo.createRowSetIterator("copyIter");
    }

    boolean rowInserted = false; // 挿入フラグ
    int lineNum = 1;             // 組織番号
    
    // コピーループ
    while (copyIter.hasNext())
    {
      // 行を取得
      Row sourceRow = copyIter.next();

      // 行を一行でも挿入した場合
      if (rowInserted)
      {
        // コピー先行を次行へ移動します。
        destVo.next();
      }
      // コピー先行を作成
      Row destRow = destVo.createRow();

      // 属性を全てコピー
      for (int i = 0; i < attrCount; i++)
      {
        byte attrKind = attrDefs[i].getAttributeKind();

        if (!(attrKind == AttributeDef.ATTR_ASSOCIATED_ROW ||
              attrKind == AttributeDef.ATTR_ASSOCIATED_ROWITERATOR ||
              attrKind == AttributeDef.ATTR_DYNAMIC))

        {

          String attrName = attrDefs[i].getName();
          if (destVo.lookupAttributeDef(attrName) != null)
          {

            Object attrVal = sourceRow.getAttribute(attrName);

            if (attrVal != null)
            {

              destRow.setAttribute(attrName, attrVal);
            }
          }
        }
      }
      // 明細番号：最大の明細番号+1をセット
      destRow.setAttribute("OrderLineNumber", new Number(lineNum++));  
      // 受注明細アドオンIDにNullを設定
      destRow.setAttribute("OrderLineId",     null);  
      // コピー先を一行挿入します。
      destVo.insertRow(destRow);
      // 挿入フラグをtrue
      rowInserted = true;
    }
    // コピー用イテレータをクローズ
    copyIter.closeRowSetIterator();
    // コピー先VOをリセットします。
    destVo.reset();

  } // copyRows

  /***************************************************************************
   * 変更に関する警告をセットします。
   ***************************************************************************
   */
  public void doWarnAboutChanges()
  {
    // 支給指示作成ヘッダVO取得
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow  = (OARow)hdrVo.first();

    // いづれかの項目に変更があった場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("VendorCode"),           hdrRow.getAttribute("DbVendorCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipToCode"),           hdrRow.getAttribute("DbShipToCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipWhseCode"),         hdrRow.getAttribute("DbShipWhseCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          hdrRow.getAttribute("DbShippedDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"),          hdrRow.getAttribute("DbArrivalDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightCarrierCode"),   hdrRow.getAttribute("DbFreightCarrierCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("OrderTypeId"),          hdrRow.getAttribute("DbOrderTypeId"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("WeightCapacityClass"),  hdrRow.getAttribute("DbWeightCapacityClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ReqDeptCode"),          hdrRow.getAttribute("DbReqDeptCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("InstDeptCode"),         hdrRow.getAttribute("DbInstDeptCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeFrom"),      hdrRow.getAttribute("DbArrivalTimeFrom"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeTo"),        hdrRow.getAttribute("DbArrivalTimeTo"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingMethodCode"),   hdrRow.getAttribute("DbShippingMethodCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightChargeClass"),   hdrRow.getAttribute("DbFreightChargeClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("TakebackClass"),        hdrRow.getAttribute("DbTakebackClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedProdDate"),   hdrRow.getAttribute("DbDesignatedProdDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedItemCode"),   hdrRow.getAttribute("DbDesignatedItemCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedBranchNo"),   hdrRow.getAttribute("DbDesignatedBranchNo"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("RcvClass"),             hdrRow.getAttribute("DbRcvClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FixClass"),             hdrRow.getAttribute("DbFixClass"))) 
    {
      // 変更に関する警告を設定
      super.setWarnAboutChanges();  
    } else
    {
      // 支給指示作成明細VO取得
      XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();

      /****************************
       * 明細行取得
       ****************************/
      Row[] rows = vo.getAllRowsInRange();
      if (rows != null || rows.length > 0) 
      {
        OARow row = null;
        for (int i = 0; i < rows.length; i++)
        {
          // i番目の行を取得
          row = (OARow)rows[i];

          /******************
           * いづれかが変更された場合
           ******************/
          if (!XxcmnUtility.isEquals(row.getAttribute("ItemId"),          row.getAttribute("DbItemId"))
           || !XxcmnUtility.isEquals(row.getAttribute("FutaiCode"),       row.getAttribute("DbFutaiCode"))
           || !XxcmnUtility.isEquals(row.getAttribute("ReqQuantity"),     row.getAttribute("DbReqQuantity"))
           || !XxcmnUtility.isEquals(row.getAttribute("LineDescription"), row.getAttribute("DbLineDescription"))) 
          {
            // 変更に関する警告を設定
            super.setWarnAboutChanges();  
            return;
          }
        }
      }
    }
  } // doWarnAboutChanges

// 2009-01-20 v1.12 T.Yoshimoto Add Start
  /***************************************************************************
   * 入庫実績日(更新用)取得を行うメソッドです。
   * @param row - 処理対象行
   * @return Date - 入庫実績日(更新用)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public Date getUpdateArrivalDate(
    OARow row
    ) throws OAException
  {

    
    Date scheduleArrivalDate  = null; // 入庫予定日を格納
    Date shippedDate          = null; // 出庫実績日を格納
    Date updateArrivalDate       = null; // 入庫実績日(更新用)を格納
    Number orderHeaderId         = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      
    // 入庫実績日が設定されているかを確認(SELECTする)
    Date chkArrivalDate = XxpoUtility.chkArrivalDate(
                            getOADBTransaction(),
                            orderHeaderId);
        
    // 入庫実績日が無い場合
    if (XxcmnUtility.isBlankOrNull(chkArrivalDate))
    {
      // 入庫予定日を取得
      scheduleArrivalDate = (Date)row.getAttribute("ArrivalDate"); 
      // 出庫実績日を取得
      shippedDate         = (Date)row.getAttribute("ShippedDate");
        
      // 出庫実績日 > 入庫予定日
      if (XxcmnUtility.chkCompareDate(1, shippedDate, scheduleArrivalDate))
      {
        // 入庫実績日へ出庫実績日を設定
        return shippedDate;

// 2009-02-03 v1.14 D.Nihei Add Start
//      // 入庫予定日 > 出庫実績日
//      }else if (XxcmnUtility.chkCompareDate(1, scheduleArrivalDate, shippedDate))
      // 入庫予定日 ≧ 出庫実績日
      }else if (XxcmnUtility.chkCompareDate(2, scheduleArrivalDate, shippedDate))
// 2009-02-03 v1.14 D.Nihei Add End
      {
        // 入庫実績日へ入庫予定日を設定
        return scheduleArrivalDate;

      }
    }

    return chkArrivalDate;
    
  } // getUpdateArrivalDate
// 2009-01-20 v1.12 T.Yoshimoto Add End
// 2009-02-13 H.Itou Add Start 本番障害#863
  /*****************************************************************************
   * 受注ヘッダアドオンの合計数量、積載重量合計、積載容積合計、積載効率を更新します。
   * @param trans        - トランザクション
   * @param orderHeaderId  - 受注ヘッダアドオンID
   * @param sumQuantity - 合計数量
   * @param smallQuantity - 小口個数
   * @param labelQuantity - ラベル枚数
   * @param sumWeight - 積載重量合計
   * @param sumCapacity - 積載容積合計
   * @param loadEfficiencyWeight - 重量積載効率
   * @param loadEfficiencyCapacity - 容積積載効率
   * @throws OAException - OA例外
   ****************************************************************************/
  public void updateSummaryInfo(
    Number orderHeaderId,
    String sumQuantity,
    Number smallQuantity,
    Number labelQuantity,
    String sumWeight,
    String sumCapacity,
  	String loadEfficiencyWeight,
    String loadEfficiencyCapacity
    ) throws OAException
  {
    String apiName = "updateSummaryInfo";
    OADBTransaction trans = getOADBTransaction();
  
  	int bindCount = 1;
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha   "                                    ); // 受注ヘッダアドオン
    sb.append("  SET    xoha.sum_quantity                = TO_NUMBER(:" + bindCount++ + ") "); // 合計数量
    sb.append("        ,xoha.small_quantity              = TO_NUMBER(:" + bindCount++ + ") "); // 小口個数
    sb.append("        ,xoha.label_quantity              = TO_NUMBER(:" + bindCount++ + ") "); // ラベル枚数
    sb.append("        ,xoha.sum_weight                  = TO_NUMBER(:" + bindCount++ + ") "); // 積載重量合計
    sb.append("        ,xoha.sum_capacity                = TO_NUMBER(:" + bindCount++ + ") "); // 積載容積合計
  	sb.append("        ,xoha.loading_efficiency_weight   = TO_NUMBER(:" + bindCount++ + ") "); // 重量積載効率
    sb.append("        ,xoha.loading_efficiency_capacity = TO_NUMBER(:" + bindCount++ + ") "); // 容積積載効率
    sb.append("        ,xoha.last_updated_by             = FND_GLOBAL.USER_ID "     ); // 最終更新者
    sb.append("        ,xoha.last_update_date            = SYSDATE "                ); // 最終更新日
    sb.append("        ,xoha.last_update_login           = FND_GLOBAL.LOGIN_ID "    ); // 最終更新ログイン
    sb.append("  WHERE  xoha.order_header_id             = :" + bindCount++ + ";  "         ); // 発注明細アドオンID
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = trans.createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      bindCount = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setString(bindCount++, XxcmnUtility.commaRemoval(sumQuantity)); // 合計数量
      if (XxcmnUtility.isBlankOrNull(smallQuantity)) 
      {
        cstmt.setNull(bindCount++, Types.INTEGER);      // 小口個数
      } else 
      {
        cstmt.setInt(bindCount++, XxcmnUtility.intValue(smallQuantity));      // 小口個数
      }
      if (XxcmnUtility.isBlankOrNull(labelQuantity)) 
      {
        cstmt.setNull(bindCount++, Types.INTEGER);
      } else 
      {
        cstmt.setInt(bindCount++, XxcmnUtility.intValue(labelQuantity));      // ラベル枚数
      }
      cstmt.setString(bindCount++, XxcmnUtility.commaRemoval(sumWeight));   // 積載重量合計
      cstmt.setString(bindCount++, XxcmnUtility.commaRemoval(sumCapacity)); // 積載容積合計
      cstmt.setString(bindCount++, loadEfficiencyWeight);                   // 重量積載効率
      cstmt.setString(bindCount++, loadEfficiencyCapacity);                 // 容積積載効率
      cstmt.setInt(bindCount++,  XxcmnUtility.intValue(orderHeaderId));     // 受注ヘッダアドオンID
      //PL/SQL実行
      cstmt.execute();
    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        // PL/SQLクローズ
        cstmt.close();

      // close中に例外が発生した場合 
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateSummaryInfo
// 2009-02-13 H.Itou Add End
// 2009-03-06 H.Iida ADD START 本番障害#1131
 /*****************************************************************************
   * 受領ボタン押下時に、明細全ての指示数が0かどうかチェックをするメソッドです。
   * @param trans      - トランザクション
   * @param requestNo  - 依頼No
   * @return boolean   - true :明細全ての指示数が0の場合
   *                   - false:指示数が0以外の明細が存在する場合
   * @throws OAException - OA例外
   ****************************************************************************/
  public static boolean chkRcvCntQuantity(
    OADBTransaction trans,
    String requestNo
  ) throws OAException
  {

    String apiName   = "chkRcvCntQuantity";

    Number cntQuantity;  // 指示数が0でない明細件数

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "                                 );
    // 依頼Noをキーに指示数が0以外の明細件数を取得
    sb.append("  SELECT COUNT(xola.quantity)         " );
    sb.append("  INTO   :1                           " );
    sb.append("  FROM   xxwsh_order_lines_all   xola " );
// 2010-04-13 M.Hokkanji Mod Start
    sb.append("        ,xxwsh_order_headers_all xoha " );
    sb.append(" WHERE   xoha.request_no = :2         " );
    sb.append("   AND   xoha.latest_external_flag = 'Y' ");
    sb.append("   AND   xola.order_header_id = xoha.order_header_id ");
//    sb.append("  WHERE  xola.request_no = :2         " );
// 2010-04-13 M.Hokkanji Mod End
    sb.append("  AND    xola.delete_flag = 'N'       " );
    sb.append("  AND    NVL(xola.quantity, 0) > 0    " );
    sb.append("  AND    ROWNUM = 1;                  " );
    sb.append("END;                                  " );

    //PL/SQLの設定を行います
    CallableStatement cstmt
      = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);

    try
    {
      // パラメータ設定(INパラメータ)
      cstmt.setString(2, requestNo);                    // 依頼No

      // パラメータ設定(OUTパラメータ)
      cstmt.registerOutParameter(1, Types.INTEGER);     // 戻り値:指示数が0以外の明細件数

      // PL/SQL実行
      cstmt.execute();

      // 明細全ての指示数が0の場合、trueを返す
      if (cstmt.getInt(1) == 0)
      {
        return true;

      // 指示数が0以外の明細が存在する場合、falseを返す
      } else
      {
        return false;
      }

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(trans);

      // ログ出力
      XxcmnUtility.writeLog(trans,
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(trans);

        // ログ出力
        XxcmnUtility.writeLog(trans,
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);

        // エラーメッセージ出力
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkRcvCntQuantity
// 2009-03-06 H.Iida ADD END
  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo440001j.server", "XxpoProvisionRequestAMLocal");
  }

  /**
   * 
   * Container's getter for OrderTypeVO1
   */
  public OAViewObjectImpl getOrderTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderTypeVO1");
  }

  /**
   * 
   * Container's getter for NotifStatusVO1
   */
  public OAViewObjectImpl getNotifStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("NotifStatusVO1");
  }

  /**
   * 
   * Container's getter for TransStatusVO1
   */
  public OAViewObjectImpl getTransStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("TransStatusVO1");
  }


  /**
   * 
   * Container's getter for XxpoProvReqtResultVO1
   */
  public XxpoProvReqtResultVOImpl getXxpoProvReqtResultVO1()
  {
    return (XxpoProvReqtResultVOImpl)findViewObject("XxpoProvReqtResultVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRequestPVO1
   */
  public XxpoProvisionRequestPVOImpl getXxpoProvisionRequestPVO1()
  {
    return (XxpoProvisionRequestPVOImpl)findViewObject("XxpoProvisionRequestPVO1");
  }

  /**
   * 
   * Container's getter for WeightCapacityVO1
   */
  public OAViewObjectImpl getWeightCapacityVO1()
  {
    return (OAViewObjectImpl)findViewObject("WeightCapacityVO1");
  }

  /**
   * 
   * Container's getter for TakebackVO1
   */
  public OAViewObjectImpl getTakebackVO1()
  {
    return (OAViewObjectImpl)findViewObject("TakebackVO1");
  }

  /**
   * 
   * Container's getter for FreightVO1
   */
  public OAViewObjectImpl getFreightVO1()
  {
    return (OAViewObjectImpl)findViewObject("FreightVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeHeaderVO1
   */
  public XxpoProvisionInstMakeHeaderVOImpl getXxpoProvisionInstMakeHeaderVO1()
  {
    return (XxpoProvisionInstMakeHeaderVOImpl)findViewObject("XxpoProvisionInstMakeHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeHeaderPVO1
   */
  public XxpoProvisionInstMakeHeaderPVOImpl getXxpoProvisionInstMakeHeaderPVO1()
  {
    return (XxpoProvisionInstMakeHeaderPVOImpl)findViewObject("XxpoProvisionInstMakeHeaderPVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvSearchVO1
   */
  public XxpoProvSearchVOImpl getXxpoProvSearchVO1()
  {
    return (XxpoProvSearchVOImpl)findViewObject("XxpoProvSearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeLineVO1
   */
  public XxpoProvisionInstMakeLineVOImpl getXxpoProvisionInstMakeLineVO1()
  {
    return (XxpoProvisionInstMakeLineVOImpl)findViewObject("XxpoProvisionInstMakeLineVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeLinePVO1
   */
  public XxpoProvisionInstMakeLinePVOImpl getXxpoProvisionInstMakeLinePVO1()
  {
    return (XxpoProvisionInstMakeLinePVOImpl)findViewObject("XxpoProvisionInstMakeLinePVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeTotalVO1
   */
  public XxpoProvisionInstMakeTotalVOImpl getXxpoProvisionInstMakeTotalVO1()
  {
    return (XxpoProvisionInstMakeTotalVOImpl)findViewObject("XxpoProvisionInstMakeTotalVO1");
  }

  /**
   * 
   * Container's getter for ShipMethodVO1
   */
  public OAViewObjectImpl getShipMethodVO1()
  {
    return (OAViewObjectImpl)findViewObject("ShipMethodVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvCopyHeaderVO1
   */
  public XxpoProvCopyHeaderVOImpl getXxpoProvCopyHeaderVO1()
  {
    return (XxpoProvCopyHeaderVOImpl)findViewObject("XxpoProvCopyHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvCopyLineVO1
   */
  public XxpoProvCopyLineVOImpl getXxpoProvCopyLineVO1()
  {
    return (XxpoProvCopyLineVOImpl)findViewObject("XxpoProvCopyLineVO1");
  }


  /**
   * 
   * Container's getter for FixClassVO1
   */
  public OAViewObjectImpl getFixClassVO1()
  {
    return (OAViewObjectImpl)findViewObject("FixClassVO1");
  }
}