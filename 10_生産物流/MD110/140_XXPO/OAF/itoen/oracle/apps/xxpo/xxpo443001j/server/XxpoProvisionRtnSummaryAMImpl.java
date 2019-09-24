/*============================================================================
* ファイル名 : XxpoProvisionRtnSummaryAMImpl
* 概要説明   : 支給返品要約:検索アプリケーションモジュール
* バージョン : 1.6
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  熊本 和郎    新規作成
* 2008-06-06 1.0  二瓶 大輔    内部変更要求#137対応
* 2008-07-01 1.1  二瓶 大輔    内部変更要求#146対応
* 2008-08-20 1.2  二瓶 大輔    ST不具合#249対応
* 2008-10-07 1.3  伊藤ひとみ   統合テスト指摘240対応
* 2009-01-26 1.4  吉元 強樹    本番#739対応
* 2009-03-13 1.5  飯田 甫      本番#1300対応
* 2019-09-05 1.6  SCSK小路     E_本稼動_15601対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;
import itoen.oracle.apps.xxpo.xxpo443001j.server.XxpoProvisionRtnSumResultVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
// 2019-09-05 Y.Shoji ADD START
import java.text.SimpleDateFormat;
// 2019-09-05 Y.Shoji ADD END

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 支給返品要約:検索画面のアプリケーションモジュールクラスです。
 * @author  ORACLE 熊本 和郎
 * @version 1.5
 ***************************************************************************
 */
public class XxpoProvisionRtnSummaryAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnSummaryAMImpl()
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
    //支給返品要約検索VO
    OAViewObject vo = getXxpoProvSearchVO1();

    //1行もない場合、空行作成
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setNewRowState(OARow.STATUS_INITIALIZED);
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("ExeType", exeType);

      // プロファイルから代表価格表ID取得
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // 代表価格表IDを取得できない場合
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10113);
      }
      row.setAttribute("RepPriceListId", repPriceListId);
    }
  } //initializeList
  
  /***************************************************************************
   * 支給返品要約画面の検索処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
    public void doSearchList() throws OAException
    {
      //支給返品検索VO取得
      XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();

      //検索条件設定
      OARow shRow = (OARow)svo.first();
      HashMap shParams = new HashMap();

      shParams.put("orderType", shRow.getAttribute("OrderType"));
      shParams.put("vendorCode", shRow.getAttribute("VendorCode"));
      shParams.put("shipToCode", shRow.getAttribute("ShipToCode"));
      shParams.put("reqNo", shRow.getAttribute("ReqNo"));
      shParams.put("shipToNo", shRow.getAttribute("ShipToNo"));
      shParams.put("transStatus", shRow.getAttribute("TransStatusCode"));
      shParams.put("notifStatus", shRow.getAttribute("NotifStatusCode"));
      shParams.put("shipDateFrom", shRow.getAttribute("ShipDateFrom"));
      shParams.put("shipDateTo", shRow.getAttribute("ShipDateTo"));
      shParams.put("arvlDateFrom", shRow.getAttribute("ArvlDateFrom"));
      shParams.put("arvlDateTo", shRow.getAttribute("ArvlDateTo"));
      shParams.put("reqDeptCode", shRow.getAttribute("ReqDeptCode"));
      shParams.put("instDeptCode", shRow.getAttribute("InstDeptCode"));
      shParams.put("shipWhseCode", shRow.getAttribute("ShipWhseCode"));
      shParams.put("exeType", shRow.getAttribute("ExeType"));
// 2009-03-13 H.Iida ADD START 本番障害#1300
      shParams.put("fixClass", shRow.getAttribute("FixClass"));
// 2009-03-13 H.Iida ADD END
// 2019-09-05 Y.Shoji ADD START
      shParams.put("sikyuReturnDate", shRow.getAttribute("SikyuReturnDate"));
// 2019-09-05 Y.Shoji ADD END
      //支給返品結果VO取得
      XxpoProvisionRtnSumResultVOImpl vo = getXxpoProvisionRtnSumResultVO1();

      //検索実行
      vo.initQuery(shParams);

    } //doSearchList

  /***************************************************************************
   * 支給指示作成ヘッダ画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param reqNo   - 依頼No
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    )
  {
    // 支給返品要約検索VO
    OAViewObject svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0) 
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey", new Number(1));
      srow.setAttribute("ExeType", exeType);
      // プロファイルから代表価格表IDを取得
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // 代表価格表を取得できない場合
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      srow.setAttribute("RepPriceListId", repPriceListId);
    }

    // 支給返品作成ヘッダPVO
    XxpoProvisionRtnMakeHeaderPVOImpl pvo = getXxpoProvisionRtnMakeHeaderPVO1();
    OARow prow = null;
    // 1行もない場合は空行作成    
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

    OARow row = null;
    // 新規の場合
    if (XxcmnUtility.isBlankOrNull(reqNo)) 
    {
      // 支給返品作成ヘッダVO取得
      XxpoProvisionRtnMakeHeaderVOImpl vo = getXxpoProvisionRtnMakeHeaderVO1();
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
      row.setAttribute("NewFlag", XxcmnConstants.STRING_Y); // 新規フラグ
      row.setAttribute("TransStatus", XxpoConstants.PROV_STATUS_NRT); //ステータス(入力中)
      row.setAttribute("NewModifyFlg", XxpoConstants.NEW_MODIFY_FLG_OFF); // 修正フラグ(OFF)
      row.setAttribute("RcvClass", XxpoConstants.RCV_CLASS_OFF); // 指示受領(OFF)
      row.setAttribute("FixClass", XxpoConstants.FIX_CLASS_OFF); // 金額確定(OFF)
      // 新規時項目制御
      handleEventInsHdr(exeType, prow, row);

    // 更新の場合
    } else
    {
      // 依頼Noで検索を実行
      doSearchHdr(reqNo);
      // 支給返品作成ヘッダVO取得
      XxpoProvisionRtnMakeHeaderVOImpl vo = getXxpoProvisionRtnMakeHeaderVO1();
      row = (OARow)vo.first();
      // 更新時項目制御
      handleEventUpdHdr(exeType, prow, row);
    }
    // 明細行の検索
    doSearchLine(exeType);
  } // initializeHdr
  /***************************************************************************
   * 支給返品作成ヘッダ画面の検索処理を行うメソッドです。
   * @param  reqNo - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchHdr(
    String reqNo
  ) throws OAException
  {
    // 支給返品作成ヘッダVO取得
    XxpoProvisionRtnMakeHeaderVOImpl vo = getXxpoProvisionRtnMakeHeaderVO1();

    // 検索を実行します。
    vo.initQuery(reqNo);
    vo.first();

    // 対象データを取得できない場合エラー
    if ((vo == null) || (vo.getFetchedRowCount() == 0))
    {
      // 支給指示作成PVO
      XxpoProvisionRtnMakeHeaderPVOImpl pvo = getXxpoProvisionRtnMakeHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // 参照のみ
      handleEventAllOffHdr(prow);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10500);
    }
  } // doSearchHdr

  /***************************************************************************
   * 支給指示作成明細画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void initializeLine(
    String exeType
  )
  {
    // 支給返品作成ヘッダVO取得
    OAViewObject hdrVvo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVvo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");  // 新規フラグ

    // 支給返品作成明細PVO
    XxpoProvisionRtnMakeLinePVOImpl pvo = getXxpoProvisionRtnMakeLinePVO1();    
    // 1行もない場合、空行作成
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0) 
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
      // PVO初期設定
      handleEventAllOnLine(prow);
    } else 
    {
      prow = (OARow)pvo.first();
    }

    // 新規フラグが「N:更新」の場合
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      handleEventUpdLine(exeType,
                         prow,
                         hdrRow);
    }
  } // initializeLine

  /***************************************************************************
   * 支給返品作成明細画面の検索処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchLine(
    String exeType
  ) throws OAException
  {
    // 支給返品作成ヘッダVO取得
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // 受注ヘッダアドオンIDを取得します。
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");  // 受注ヘッダアドオンID
    // 支給返品作成明細VO取得
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();
    // 検索を実行します。
    vo.initQuery(exeType, orderHeaderId);
    vo.first();
    // 1行も存在しない場合、1行作成
    if (vo.getFetchedRowCount() == 0) 
    {
      addRow(exeType);
    }
    // 支給返品作成合計VO取得
    XxpoProvisionRtnMakeTotalVOImpl totalVo = getXxpoProvisionRtnMakeTotalVO1();
    // 検索を実行します。
    totalVo.initQuery(orderHeaderId);
  } // doSearchLine

  /***************************************************************************
   * 行挿入処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void addRow(
    String exeType
  ) throws OAException
  {
    // 初期化
    OARow maxRow = null;
    Number maxOrderLineNumber = new Number(0);
    // 支給返品作成ヘッダVO取得
    OAViewObject hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // 受注ヘッダアドオンID取得
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");
    // 支給返品作成明細VO取得
    OAViewObject vo = getXxpoProvisionRtnMakeLineVO1();
    // 最大明細番号取得
    maxRow = (OARow)vo.last();
    // レコードが存在する場合
    if (maxRow != null) 
    {
      maxOrderLineNumber = (Number)maxRow.getAttribute("OrderLineNumber");
    }
    // 明細VOに挿入する行を作成
    OARow row = (OARow)vo.createRow();
    // Switcherの制御
    row.setAttribute("ItemSwitcher", "ItemNo");  // 品目
    row.setAttribute("FutaiSwitcher", "FutaiCode");  // 付帯
    row.setAttribute("ReqSwitcher", "ReqQuantity"); // 依頼数量
    row.setAttribute("PriceSwitcher", "UnitPrice"); // 単価
    row.setAttribute("DescSwitcher", "LineDescription"); // 備考
    row.setAttribute("ShippedSwitcher", "ShippedIconDisable"); // 出庫実績アイコン
    row.setAttribute("ShipToSwitcher", "ShipToIconDisable");  // 入庫実績アイコン
    row.setAttribute("ReserveSwitcher", "ReserveIconDisable");  // 引当アイコン
    row.setAttribute("DeleteSwitcher" , "DeleteEnable");  // 削除アイコン
    // デフォルト値の設定
    row.setAttribute("RecordType"     , XxcmnConstants.STRING_Y); // 新規行
    row.setAttribute("FutaiCode"      , XxcmnConstants.STRING_ZERO);  // 付帯
    row.setAttribute("OrderLineNumber", maxOrderLineNumber.add(1)); // 行番号
    row.setAttribute("OrderHeaderId"  , orderHeaderId); // 受注ヘッダアドオンID
    // 作成した行の挿入
    vo.last();
    vo.next();
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);
    // 変更に関する警告を設定
    super.setWarnAboutChanges();  
  } // AddRow

  /*****************************************************************************
   * 指定された行を削除します。
   * @param exeType - 起動タイプ
   * @param orderLineNumber - 明細番号
   ****************************************************************************/
  public void doDeleteLine(
    String exeType,
    String orderLineNumber
  ) 
  {
    // 支給返品作成ヘッダVO取得
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String reqNo = (String)hdrRow.getAttribute("RequestNo");  // 依頼No
    String newFlag = (String)hdrRow.getAttribute("NewFlag");  // 新規フラグ
    // 支給返品作成明細VO取得
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();
    // 削除対象行を取得
    OARow row = (OARow)vo.getFirstFilteredRow("OrderLineNumber", new Number(Integer.parseInt(orderLineNumber)));
    // 受注明細アドオンIDを取得
    Number orderLineId = (Number)row.getAttribute("OrderLineId");

    Row[] rows = null;
    rows = vo.getAllRowsInRange();
    // 更新行の明細が1件しかない場合
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
    if ((row != null)
      && (XxcmnUtility.isBlankOrNull(orderLineId))) 
    {
      // 挿入行削除
      row.remove();
      // 削除処理成功メッセージを表示
      putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);

    // 更新行の場合
    } else 
    {
      // 削除チェック処理
      chkOrderLineDel(vo, hdrRow, row);
      // 排他チェック
      chkLockAndExclusive(hdrVo, hdrRow);
      // 削除処理
      XxpoUtility.deleteOrderLine(getOADBTransaction(), orderLineId);
      // 受注ヘッダアドオンIDを取得
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");
      // 明細の合計値取得
      HashMap retParams = XxpoUtility.getSummaryDataOrderLine(
                            getOADBTransaction(),
                            orderHeaderId);
      hdrRow.setAttribute("SumQuantity", retParams.get("sumQuantity")); // 合計数量
      hdrRow.setAttribute("SumWeight", retParams.get("sumWeight"));     // 積載重量合計
      hdrRow.setAttribute("SumCapacity", retParams.get("sumCapacity")); // 積載容積合計
      String sumQuantity = (String)retParams.get("sumQuantity");
      String sumWeight = (String)retParams.get("sumWeight");
      String sumCapacity = (String)retParams.get("sumCapacity");
      // ヘッダ更新処理
      XxpoUtility.updateSummaryInfo(getOADBTransaction(),
                                    orderHeaderId,
                                    sumQuantity,
                                    null,
                                    null,
                                    sumWeight,
                                    sumCapacity);
      // コミット処理 
      doCommit(reqNo);
      // 削除処理成功メッセージを表示
      putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);
    }
  } // doDeleteLine

  /***************************************************************************
   * 支給返品要約画面の金額確定処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
    public void doAmountFixList() throws OAException
    {
      ArrayList exceptions = new ArrayList(100);
      boolean exeFlag = false;

      //処理対象を取得
      OAViewObject vo = getXxpoProvisionRtnSumResultVO1();
      Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

      //未選択チェック
      if ((rows == null) || (rows.length == 0))
      {
        //エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10144
        );
      } else 
      {
        OARow row = null;
        //価格設定チェックloop
        for (int i = 0; i < rows.length; i++) 
        {
          //i番目の行を取得
          row = (OARow)rows[i];
          //金額確定前チェック
          chkAmountFix(vo, row, exceptions);
        }
        //エラーがあった場合、例外をスローします。
        if (exceptions.size() > 0) 
        {
          OAException.raiseBundledOAException(exceptions);
        }
        //更新処理loop
        for (int i = 0; i < rows.length; i++) 
        {
          //i番目の行を取得
          row = (OARow)rows[i];
          Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); //受注ヘッダアドオンID

          //排他チェック&ロック
          chkLockAndExclusive(vo, row);

          //価格確定処理実行
          XxpoUtility.updateFixClass(
            getOADBTransaction(),
            orderHeaderId,
            XxpoConstants.FIX_CLASS_ON
          );
          exeFlag = true;
        }

        if (exeFlag) 
        {
          //コミット発行
          doCommitList();
        }
      }
    } //doAmountFixList

  /***************************************************************************
   * 支給指示ヘッダ画面のコミット・再検索処理を行うメソッドです。
   * @param reqNo - 依頼No
   ***************************************************************************
   */
  public void doCommit(
    String reqNo
  ) 
  {
    // コミット発行
    XxpoUtility.commit(getOADBTransaction());
    // ヘッダの再検索を行います
    doSearchHdr(reqNo);
    // 支給依頼要約検索VO
    OAViewObject vo = getXxpoProvSearchVO1();
    OARow row = (OARow)vo.first();
    String exeType = (String)row.getAttribute("ExeType");
    // 明細の再検索を行います
    doSearchLine(exeType);
  } // doCommit

  /***************************************************************************
   * 支給指示要約画面のコミット・再検索処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
    public void doCommitList() throws OAException
    {
      //コミット発行
      XxpoUtility.commit(getOADBTransaction());
      //再検索を行います。
      doSearchList();
      //更新完了メッセージ
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30042,
        null,
        OAException.INFORMATION,
        null
      );
    } //doCommitList

  /***************************************************************************
   * 支給返品作成ヘッダ画面の支給取消処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
    public void doProvCancel() throws OAException
    {
      ArrayList exceptions = new ArrayList(100);
      boolean exeFlag = false;

      // 支給返品作成ヘッダVO取得
      OAViewObject vo = getXxpoProvisionRtnMakeHeaderVO1();
      OARow row = (OARow)vo.first();

      // エラーがあった場合はエラーをスローします。
      if (exceptions.size() > 0) 
      {
        OAException.raiseBundledOAException(exceptions);
      }

      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
      String requestNo = (String)row.getAttribute("RequestNo"); // 依頼No

      // 排他チェック
      chkLockAndExclusive(vo, row);

      // ステータスを「取消」に更新します。
      XxpoUtility.updateTransStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.PROV_STATUS_CAN
      );

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
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;

    // 支給返品作成ヘッダVO取得
    OAViewObject vo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // 次へチェック
    chkNext(vo, row, exceptions);
    // エラーがあった場合はエラーをスローします。
    if (exceptions.size() > 0) 
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // 変更に関する警告処理
    doWarnAboutChanges();

  } // doNext

  /***************************************************************************
   * 依頼数を指示数へコピーするメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doCopyReqQty() throws OAException 
  {
    // 支給返品作成明細情報VO取得
    OAViewObject vo = getXxpoProvisionRtnMakeLineVO1();
    Row[] rows= vo.getAllRowsInRange();
    if ((rows != null) || (rows.length > 0)) 
    {
      OARow row = null;
      String reqQty = null;
      String dbReqQty = null;
      for (int i = 0; i < rows.length; i++) 
      {
        row = (OARow)rows[i];
        reqQty = (String)row.getAttribute("ReqQuantity"); // 依頼数(画面)
        dbReqQty = (String)row.getAttribute("DbReqQuantity"); // 依頼数(DB)
        // 依頼数が変更された場合、指示数へコピー
        if (!XxcmnUtility.chkCompareNumeric(3, reqQty, dbReqQty)) 
        {
          row.setAttribute("InstQuantity", reqQty);
        }
      }
    }
  } // doCopyReqQty

  /***************************************************************************
   * 支給返品明細画面の適用処理を行うメソッドです。
   * @param  exeType - 起動タイプ
   * @return  HashMap - 戻り値群
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
  ) throws OAException 
  {
    boolean exeFlag = false;  // 実行フラグ

    // チェック処理
    chkOrderLine(exeType);

    // 支給返品作成ヘッダVO取得
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");  // 新規フラグ
    String reqNo = (String)hdrRow.getAttribute("RequestNo");   // 依頼No
    String tokenName = null;

    // 新規フラグが「N:更新」の場合
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // 排他チェック
      chkLockAndExclusive(hdrVo, hdrRow);
      tokenName = XxpoConstants.TOKEN_NAME_UPD;
    // 新規フラグが「Y:新規」の場合
    } else 
    {
      // 依頼Noを取得      
      reqNo = XxcmnUtility.getSeqNo(getOADBTransaction(), "依頼No");
      hdrRow.setAttribute("RequestNo", reqNo);

      // 受注ヘッダアドオンIDを取得
      Number orderHeaderId = XxpoUtility.getOrderHeaderId(getOADBTransaction());
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
    retParams.put("tokenName", tokenName);
    retParams.put("reqNo", reqNo);
    return retParams;
  } // doApply

  /***************************************************************************
   * 挿入・更新処理を行うメソッドです。
   * @return boolean - True:ヘッダまたは明細を更新。 False:ヘッダ、明細更新せず。
   * @param newFlag - 新規フラグ Y:新規、N:更新
   * @param hdrRow  - ヘッダ行オブジェクト
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean doExecute(
    String newFlag,
    OARow hdrRow,
    String exeType
  ) throws OAException
  {
    // 支給返品明細VO
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();
    boolean sumQtyFlag = false; // 合計数量変更フラグ
    boolean lineExeFlag = false;  // 明細実行フラグ
    boolean hdrExeFlag = false; // ヘッダ実行フラグ
    // 明細更新行取得
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((updRows != null) || (updRows.length > 0)) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++) 
      {
        // i番目の行を取得
        updRow = (OARow)updRows[i];
        // 品目ID、付帯コード、依頼数、単価、備考が変更された場合
        if (!XxcmnUtility.isEquals(updRow.getAttribute("ItemId"),updRow.getAttribute("DbItemId")) 
         || !XxcmnUtility.isEquals(updRow.getAttribute("FutaiCode"),updRow.getAttribute("DbFutaiCode"))
         || !XxcmnUtility.isEquals(updRow.getAttribute("ReqQuantity"),updRow.getAttribute("DbReqQuantity"))
         || !XxcmnUtility.isEquals(updRow.getAttribute("UnitPriceNum"),updRow.getAttribute("DbUnitPriceNum"))
         || !XxcmnUtility.isEquals(updRow.getAttribute("LineDescription"),updRow.getAttribute("DbLineDescription"))
        )
        {
          // 更新処理
          updateOrderLine(updRow);
          // 明細実行フラグをTrueに変更
          lineExeFlag = true;
        }

        // 指示数が変更された場合
        if (!XxcmnUtility.isEquals(
               XxcmnUtility.commaRemoval((String)updRow.getAttribute("InstQuantity")),
               XxcmnUtility.commaRemoval((String)updRow.getAttribute("DbInstQuantity"))
               )
            )
        {
          // 合計数量変更フラグをtrueに変更
          sumQtyFlag = true;
        }
      }
    }

    // 明細追加行取得
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0)) 
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++) 
      {
        // i番目の行を取得
        insRow = (OARow)insRows[i];

        // 全てブランクの行は無視する
        if (!XxcmnUtility.isBlankOrNull(insRow.getAttribute("ItemNo"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("FutaiCode"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("ReqQuantity"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("UnitPrice"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("LineDescription"))
        ) 
        {
          // 挿入処理
          insertOrderLine(hdrRow, insRow);
          // 明細実行フラグをtrueに変更
          lineExeFlag = true;
          // 合計数量変更フラグをtrueに変更
          sumQtyFlag = true;
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

    // 明細が実行されていた場合
    if (lineExeFlag) 
    {
      // 受注ヘッダアドオンIDを取得
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");
      // 明細の合計値取得
      HashMap retParams = XxpoUtility.getSummaryDataOrderLine(
                            getOADBTransaction(),
                            orderHeaderId);
      hdrRow.setAttribute("SumQuantity", retParams.get("sumQuantity")); // 合計数量
      hdrRow.setAttribute("SumWeight", retParams.get("sumWeight"));     // 積載重量合計
      hdrRow.setAttribute("SumCapacity", retParams.get("sumCapacity")); // 積載容積合計
    }
    // ヘッダ新規追加の場合
    if (XxcmnConstants.STRING_Y.equals(newFlag)) 
    {
      // 挿入処理
      insertOrderHdr(hdrRow);
      // ヘッダ実行フラグをtrueに変更
      hdrExeFlag = true;

    // ヘッダ更新の場合
    } else 
    {
      // 以下が更新された場合
      // ・発生区分 ・重量容積区分    ・依頼部署    ・指示部署 ・取引先
      // ・配送先   ・出庫倉庫       ・運送業者    ・出庫日   ・有償支給年月(返品)
      // ・入庫日   ・着荷時間(From) ・着荷時間(To)・配送区分 ・運賃区分
      // ・引取区分 ・製造日         ・製造品目    ・製造番号 ・摘要
      // ・指示受領 ・金額確定       ・合計数量変更フラグsumQtyFlag
      if (!XxcmnUtility.isEquals(hdrRow.getAttribute("OrderTypeId"),          hdrRow.getAttribute("DbOrderTypeId"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("WeightCapacityClass"),  hdrRow.getAttribute("DbWeightCapacityClass"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ReqDeptCode"),          hdrRow.getAttribute("DbReqDeptCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("InstDeptCode"),         hdrRow.getAttribute("DbInstDeptCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("VendorCode"),           hdrRow.getAttribute("DbVendorCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipToCode"),           hdrRow.getAttribute("DbShipToCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipWhseCode"),         hdrRow.getAttribute("DbShipWhseCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightCarrierCode"),   hdrRow.getAttribute("DbFreightCarrierCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          hdrRow.getAttribute("DbShippedDate"))
// 2019-09-05 Y.Shoji ADD START
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("SikyuReturnDate"),      hdrRow.getAttribute("DbSikyuReturnDate"))
// 2019-09-05 Y.Shoji ADD END
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"),          hdrRow.getAttribute("DbArrivalDate"))
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
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("FixClass"),             hdrRow.getAttribute("DbFixClass"))
       || sumQtyFlag)
       {
          // 更新処理
          updateOrderHdr(hdrRow);

// 2009-01-26 v1.4 T.Yoshimoto Add Start 本番#739
        // 有償金額確定区分が「確定」の場合
        String fixClass       = (String)hdrRow.getAttribute("FixClass");      // 有償金額確定
        Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID
        if (XxpoConstants.FIX_CLASS_ON.equals(fixClass))
        {

          // 有償金額確定処理を実行します。
          XxpoUtility.updateFixClass(
            getOADBTransaction(),
            orderHeaderId,
            XxpoConstants.FIX_CLASS_ON);
        }
// 2009-01-26 v1.4 T.Yoshimoto Add End 本番#739

          // ヘッダ実行フラグをtrueに変更
          hdrExeFlag = true;
       }
    }
    // ヘッダ、明細のいずれかが登録・更新された場合trueを返す
    if (hdrExeFlag || lineExeFlag) 
    {
      return true;
    } else 
    {
      return false;
    }
  } // doExecute

  /*****************************************************************************
   * 受注明細アドオンのデータを更新します。
   * @param updRow - 更新対象行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void updateOrderLine(
    OARow updRow
  ) throws OAException
  {
    String apiName = "updateOrderLine";

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.shipping_inventory_item_id = :1 ");  // 出荷品目ID
    sb.append("        ,xola.shipping_item_code         = :2 ");  // 出荷品目
    sb.append("        ,xola.quantity                   = TO_NUMBER(:3) ");  // 数量
    sb.append("        ,xola.uom_code                   = :4 ");  // 単位
    sb.append("        ,xola.based_request_quantity     = TO_NUMBER(:5) ");  // 拠点依頼数量
    sb.append("        ,xola.request_item_id            = :6 ");  // 依頼品目ID
    sb.append("        ,xola.request_item_code          = :7 ");  // 依頼品目
    sb.append("        ,xola.futai_code                 = :8 ");  // 付帯コード
    sb.append("        ,xola.line_description           = :9 ");  // 摘要
    sb.append("        ,xola.unit_price                 = TO_NUMBER(:10) "); // 単価
    sb.append("        ,xola.weight                     = TO_NUMBER(:11) "); // 重量
    sb.append("        ,xola.capacity                   = TO_NUMBER(:12) "); // 容積
    sb.append("        ,xola.last_updated_by            = FND_GLOBAL.USER_ID ");  // 最終更新者
    sb.append("        ,xola.last_update_date           = SYSDATE ");             // 最終更新日
    sb.append("        ,xola.last_update_login          = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  xola.order_line_id = :13 ; ");             // 受注明細アドオンID
    sb.append("END; ");

    // PL/SQLの設定を行います。
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                getOADBTransaction().DEFAULT);
    try 
    {
      // 情報を取得
      Number invItemId        = (Number)updRow.getAttribute("InvItemId");       // 出荷品目ID
      String itemNo           = (String)updRow.getAttribute("ItemNo");          // 出荷品目
      String instQuantity     = (String)updRow.getAttribute("InstQuantity");    // 数量
      String itemUm           = (String)updRow.getAttribute("ItemUm");          // 単位
      String reqQuantity      = (String)updRow.getAttribute("ReqQuantity");     // 拠点依頼数量
      Number whseInvItemId    = (Number)updRow.getAttribute("WhseInvItemId");   // 依頼品目ID
      String whseItemNo       = (String)updRow.getAttribute("WhseItemNo");      // 依頼品目
      String futaiCode        = (String)updRow.getAttribute("FutaiCode");       // 付帯コード
      String lineDescription  = (String)updRow.getAttribute("LineDescription"); // 摘要
      String unitPrice        = XxcmnUtility.stringValue(
                                  (Number)updRow.getAttribute("UnitPriceNum")); // 単価
      String weight           = (String)updRow.getAttribute("Weight");          // 重量
      String capacity         = (String)updRow.getAttribute("Capacity");        // 容積
      Number orderLineId      = (Number)updRow.getAttribute("OrderLineId");     // 受注明細アドオンID

      int i = 1;
      // パラメータ設定
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));
      cstmt.setString(i++, itemNo);
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity));
      cstmt.setString(i++, itemUm);
      cstmt.setString(i++, reqQuantity);
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));
      cstmt.setString(i++, whseItemNo);
      cstmt.setString(i++, futaiCode);
      cstmt.setString(i++, lineDescription);
      cstmt.setString(i++, unitPrice);
      cstmt.setString(i++, weight);
      cstmt.setString(i++, capacity);
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));
      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s) 
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                               XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine

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
    String apiName = "insertOrderLine";    

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_line  xxwsh_order_lines_all%ROWTYPE; ");
    sb.append("  ln_line_id NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  SELECT xxwsh_order_lines_all_s1.NEXTVAL INTO ln_line_id FROM DUAL; ");
    sb.append("  lr_line.order_line_id               := ln_line_id; ");
    sb.append("  lr_line.order_header_id             := :1; ");
    sb.append("  lr_line.order_line_number           := :2; ");
    sb.append("  lr_line.request_no                  := :3; ");
    sb.append("  lr_line.shipping_inventory_item_id  := :4; ");
    sb.append("  lr_line.shipping_item_code          := :5; ");
    sb.append("  lr_line.quantity                    := TO_NUMBER(:6); ");
    sb.append("  lr_line.uom_code                    := :7; ");
    sb.append("  lr_line.based_request_quantity      := TO_NUMBER(:8); ");
    sb.append("  lr_line.request_item_id             := :9; ");
    sb.append("  lr_line.request_item_code           := :10; ");
    sb.append("  lr_line.futai_code                  := :11; ");
    sb.append("  lr_line.delete_flag                 := 'N'; ");
    sb.append("  lr_line.line_description            := :12; ");
    sb.append("  lr_line.unit_price                  := :13; ");
    sb.append("  lr_line.weight                      := TO_NUMBER(:14); ");
    sb.append("  lr_line.capacity                    := TO_NUMBER(:15); ");
    sb.append("  lr_line.created_by                  := FND_GLOBAL.USER_ID; ");
    sb.append("  lr_line.creation_date               := SYSDATE; ");
    sb.append("  lr_line.last_updated_by             := FND_GLOBAL.USER_ID; ");
    sb.append("  lr_line.last_update_date            := SYSDATE; ");
    sb.append("  lr_line.last_update_login           := FND_GLOBAL.LOGIN_ID; ");
    sb.append("  INSERT INTO xxwsh_order_lines_all VALUES lr_line; ");
    sb.append("END; ");
    // PL/SQLの設定を行います。
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
      String unitPrice       = XxcmnUtility.stringValue((Number)insRow.getAttribute("UnitPriceNum"));    // 単価
      String weight          = (String)insRow.getAttribute("Weight");          // 重量
      String capacity        = (String)insRow.getAttribute("Capacity");        // 容積

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // 受注ヘッダアドオンID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineNumber));  // 明細番号
      cstmt.setString(i++, requestNo);                            // 依頼No
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));        // 出荷品目ID
      cstmt.setString(i++, itemNo);                               // 出荷品目
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity)); // 数量
      cstmt.setString(i++, itemUm);                               // 単位
      cstmt.setString(i++, reqQuantity);                          // 拠点依頼数量
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));    // 依頼品目ID
      cstmt.setString(i++, whseItemNo);                           // 依頼品目
      cstmt.setString(i++, futaiCode);                            // 付帯コード
      cstmt.setString(i++, lineDescription);                      // 摘要
      cstmt.setString(i++, unitPrice);                            // 単価
      cstmt.setString(i++, weight);                               // 重量
      cstmt.setString(i++, capacity);                             // 容積

      // PL/SQL実行
      cstmt.execute();

    } catch(SQLException s) 
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderLine

  /*****************************************************************************
   * 受注ヘッダアドオンにデータを追加します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void insertOrderHdr(
    OARow hdrRow
  ) throws OAException
  {
    String apiName = "insertOrderHdr";

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_hdr  xxwsh_order_headers_all%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_hdr.order_header_id               := :1; ");  // 受注ヘッダアドオンID
    sb.append("  lr_hdr.order_type_id                 := :2; ");  // 受注タイプID
    sb.append("  lr_hdr.organization_id               := FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'); ");  // 組織ID
    sb.append("  lr_hdr.latest_external_flag          := 'Y'; "); // 最新フラグ
    sb.append("  lr_hdr.ordered_date                  := SYSDATE; "); // 受注日
    sb.append("  lr_hdr.customer_id                   := :3; ");  // 顧客ID
    sb.append("  lr_hdr.customer_code                 := :4; ");  // 顧客
    sb.append("  lr_hdr.shipping_instructions         := :5; ");  // 出荷指示
    sb.append("  lr_hdr.request_no                    := :6; ");  // 依頼No
    sb.append("  lr_hdr.req_status                    := '05'; ");  // ステータス
    sb.append("  lr_hdr.schedule_ship_date            := :7; "); // 出荷予定日
    sb.append("  lr_hdr.schedule_arrival_date         := :8; "); // 着荷予定日
    sb.append("  lr_hdr.freight_charge_class          := :9; "); // 運賃区分
    sb.append("  lr_hdr.amount_fix_class              := :10; "); // 有償金額確定区分
    sb.append("  lr_hdr.deliver_from_id               := :11; "); // 出荷元ID
    sb.append("  lr_hdr.deliver_from                  := :12; "); // 出荷元保管場所
    sb.append("  lr_hdr.prod_class                    := FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY'); ");  // 商品区分
    sb.append("  lr_hdr.sum_quantity                  := TO_NUMBER(:13); "); // 合計数量
    sb.append("  lr_hdr.sum_weight                    := TO_NUMBER(:14); "); // 積載重量合計
    sb.append("  lr_hdr.sum_capacity                  := TO_NUMBER(:15); "); // 積載容積合計
    sb.append("  lr_hdr.actual_confirm_class          := 'N'; "); // 実績計上済区分
    sb.append("  lr_hdr.performance_management_dept   := :16; "); // 成績管理部署
    sb.append("  lr_hdr.instruction_dept              := :17; "); // 指示部署
    sb.append("  lr_hdr.vendor_id                     := :18; "); // 取引先ID
    sb.append("  lr_hdr.vendor_code                   := :19; "); // 取引先
    sb.append("  lr_hdr.vendor_site_id                := :20; "); // 取引先サイトID
    sb.append("  lr_hdr.vendor_site_code              := :21; "); // 取引先サイト
    sb.append("  lr_hdr.shipped_date                  := :22; "); // 出荷日
    sb.append("  lr_hdr.arrival_date                  := :23; "); // 着荷日
// 2019-09-05 Y.Shoji ADD START
    sb.append("  lr_hdr.sikyu_return_date             := :24; "); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END
    sb.append("  lr_hdr.created_by                    := FND_GLOBAL.USER_ID; ");  // 作成者
    sb.append("  lr_hdr.creation_date                 := SYSDATE; "); // 作成日
    sb.append("  lr_hdr.last_updated_by               := FND_GLOBAL.USER_ID; ");  // 最終更新者
    sb.append("  lr_hdr.last_update_date              := SYSDATE; "); // 最終更新日
    sb.append("  lr_hdr.last_update_login             := FND_GLOBAL.LOGIN_ID; ");  // 最終更新ログイン
    sb.append("  INSERT INTO xxwsh_order_headers_all VALUES lr_hdr; ");
    sb.append("END; ");

    // PL/SQLの設定を行います
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
      String requestNo           = (String)hdrRow.getAttribute("RequestNo");             // 依頼No
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // 出庫予定日(=出庫日)
      String freightChargeClass  = (String)hdrRow.getAttribute("FreightChargeClass");    // 運賃区分
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // 金額確定
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // 出庫倉庫ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // 出庫倉庫
      String sumQuantity         = XxcmnUtility.stringValue((Number)hdrRow.getAttribute("SumQuantity")); // 合計数量
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // 積載重量合計
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // 積載容積合計
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // 依頼部署
      String instDeptCode        = (String)hdrRow.getAttribute("ReqDeptCode");           // 指示部署(=依頼部署)
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // 取引先ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // 取引先
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // 配送先ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // 配送先
// 2019-09-05 Y.Shoji ADD START
      String sikyuReturnDateStr  = (String)hdrRow.getAttribute("SikyuReturnDate");       // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END

      int i = 1;
      // パラメータ設定
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // 受注ヘッダアドオンID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId));      // 発生区分
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));       // 顧客ID
      cstmt.setString(i++, customerCode);                         // 顧客
      cstmt.setString(i++, instructions);                         // 摘要
      cstmt.setString(i++, requestNo);                            // 依頼No
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 出庫予定日
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 入庫予定日
      cstmt.setString(i++, XxcmnConstants.OBJECT_OFF);            // 運賃区分
      cstmt.setString(i++, fixClass);                             // 金額確定
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // 出庫倉庫ID
      cstmt.setString(i++, shipWhseCode);                         // 出庫倉庫
      cstmt.setString(i++, sumQuantity);                          // 合計数量
      cstmt.setString(i++, sumWeight);                            // 積載重量合計
      cstmt.setString(i++, sumCapacity);                          // 積載容積合計
      cstmt.setString(i++, reqDeptCode);                          // 依頼部署
      cstmt.setString(i++, instDeptCode);                         // 指示部署
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // 取引先ID
      cstmt.setString(i++, vendorCode);                           // 取引先
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // 配送先ID
      cstmt.setString(i++, shipToCode);                           // 配送先
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 出庫日
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 入庫日
// 2019-09-05 Y.Shoji ADD START
      cstmt.setDate(i++, XxcmnUtility.dateValue(sikyuReturnDateStr)); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END

      // PL/SQL実行
      cstmt.execute();
      
    // PL/SQL実行時例外の場合
    } catch(SQLException s) 
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        // 処理中にエラーが発生した場合を想定する
        cstmt.close();
      } catch(SQLException s) 
      {
        // ロールバック
          XxpoUtility.rollBack(getOADBTransaction());
          XxcmnUtility.writeLog(getOADBTransaction(),
                                XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
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
    String apiName = "updateOrderHdr";

    // PL/SQLの作成を行います。
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET   xoha.order_type_id         = :1 " ); // 受注タイプID
    sb.append("       ,xoha.customer_id           = :2 " ); // 顧客ID
    sb.append("       ,xoha.customer_code         = :3 " ); // 顧客
    sb.append("       ,xoha.shipping_instructions = :4 " ); // 出荷指示
    sb.append("       ,xoha.schedule_ship_date    = :5 "); // 出荷予定日
    sb.append("       ,xoha.schedule_arrival_date = :6 "); // 着荷予定日
    sb.append("       ,xoha.amount_fix_class      = :7 " ); // 有償金額確定区分
    sb.append("       ,xoha.deliver_from_id       = :8 " ); // 出荷元ID
    sb.append("       ,xoha.deliver_from          = :9 " ); // 出荷元保管場所
    sb.append("       ,xoha.sum_quantity          = TO_NUMBER(:10) " ); // 合計数量
    sb.append("       ,xoha.sum_weight            = TO_NUMBER(:11) " ); // 積載重量合計
    sb.append("       ,xoha.sum_capacity          = TO_NUMBER(:12) ");  // 積載容積合計
    sb.append("       ,xoha.performance_management_dept = :13 " ); // 成績管理部署
    sb.append("       ,xoha.instruction_dept      = :14 " ); // 指示部署
    sb.append("       ,xoha.vendor_id             = :15 " ); // 取引先ID
    sb.append("       ,xoha.vendor_code           = :16 " ); // 取引先
    sb.append("       ,xoha.vendor_site_id        = :17 " ); // 取引先サイトID
    sb.append("       ,xoha.vendor_site_code      = :18 " ); // 取引先サイト
    sb.append("       ,xoha.shipped_date          = :19 "); // 出庫日
    sb.append("       ,xoha.arrival_date          = :20 "); // 着荷日
// 2019-09-05 Y.Shoji ADD START
    sb.append("       ,xoha.sikyu_return_date     = :21 "); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END
    sb.append("       ,xoha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("       ,xoha.last_update_date      = SYSDATE "             ); // 最終更新日
    sb.append("       ,xoha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
// 2019-09-05 Y.Shoji MOD START
//    sb.append("  WHERE xoha.order_header_id = :21; "); // 受注ヘッダアドオンID
    sb.append("  WHERE xoha.order_header_id = :22; "); // 受注ヘッダアドオンID
// 2019-09-05 Y.Shoji MOD END
    sb.append("END; ");

    // PL/SQLの設定を行います。
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
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // 出庫予定日
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // 金額確定
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // 出庫倉庫ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // 出庫倉庫
      String sumQuantity         = XxcmnUtility.stringValue((Number)hdrRow.getAttribute("SumQuantity")); // 合計数量
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // 積載重量合計
      sumWeight = XxcmnUtility.commaRemoval(sumWeight);
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // 積載容積合計
      sumCapacity = XxcmnUtility.commaRemoval(sumCapacity);
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // 依頼部署
// 2009-01-26 v1.14 T.Yoshimoto Mod Start 本番#739
      //String instDeptCode        = (String)hdrRow.getAttribute("ReqDeptCode");          // 指示部署
      String instDeptCode        = (String)hdrRow.getAttribute("InstDeptCode");          // 指示部署
// 2009-01-26 v1.14 T.Yoshimoto Mod End 本番#739
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // 取引先ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // 取引先
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // 配送先ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // 配送先
// 2019-09-05 Y.Shoji ADD START
      String sikyuReturnDateStr  = (String)hdrRow.getAttribute("SikyuReturnDate");       // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END
      Number orderHeaderId       = (Number)hdrRow.getAttribute("OrderHeaderId");         // 受注ヘッダアドオンID
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId));      // 発生区分
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));       // 顧客ID
      cstmt.setString(i++, customerCode);                         // 顧客
      cstmt.setString(i++, instructions);                         // 摘要
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 出荷予定日(=出庫日)  
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 着荷予定日(=出庫日)  
      cstmt.setString(i++, fixClass);                             // 金額確定
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // 出庫倉庫ID
      cstmt.setString(i++, shipWhseCode);                         // 出庫倉庫
      cstmt.setString(i++, sumQuantity);                          // 合計数量
      cstmt.setString(i++, sumWeight);                            // 積載重量合計
      cstmt.setString(i++, sumCapacity);                          // 積載容積合計
      cstmt.setString(i++, reqDeptCode);                          // 依頼部署
      cstmt.setString(i++, instDeptCode);                         // 指示部署
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // 取引先ID
      cstmt.setString(i++, vendorCode);                           // 取引先
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // 配送先ID
      cstmt.setString(i++, shipToCode);                           // 配送先
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 出荷日  
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // 着荷日(=出庫日) 
// 2019-09-05 Y.Shoji ADD START
      cstmt.setDate(i++, XxcmnUtility.dateValue(sikyuReturnDateStr)); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END 
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // 受注ヘッダアドオンID

      // PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s) 
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      // 処理中にエラーが発生した場合を想定する
      try 
      {
        cstmt.close();
      } catch(SQLException s) 
      {
          // ロールバック
          XxpoUtility.rollBack(getOADBTransaction());
          XxcmnUtility.writeLog(getOADBTransaction(),
                                XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHdr

  /***************************************************************************
   * 処理成功メッセージ表示を行うメソッドです。
   * @param tokenName - トークン値
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void putSuccessMessage(
    String tokenName
  ) throws OAException
  {
    // トークンを生成します。
    MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,tokenName) };
    // 処理成功メッセージ
    throw new OAException(
      XxcmnConstants.APPL_XXCMN,
      XxcmnConstants.XXCMN05001, 
      tokens,
      OAException.INFORMATION, 
      null);
  } // putSuccessMessage

  /***************************************************************************
   * 次へボタン押下時のチェックを行うメソッドです。
   * @param vo - ヘッダビューオブジェクト
   * @param row - ヘッダ行オブジェクト
   * @param exceptions - エラー情報格納配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkNext(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    // 依頼部署必須チェック
    Object reqDeptCode = row.getAttribute("ReqDeptCode");
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
    // 取引先必須チェック
    Object vendorCode = row.getAttribute("VendorCode");
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

    // 配送先必須チェック
    Object shipToCode = row.getAttribute("ShipToCode");
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

    // 出庫倉庫必須チェック
    Object shipWhseCode = row.getAttribute("ShipWhseCode");
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

    // 出庫日必須チェック
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // システム日付を取得
    Date currentDate = getOADBTransaction().getCurrentDBDate();
    if (XxcmnUtility.isBlankOrNull(shippedDate)) 
    {
      exceptions.add( new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "ShippedDate",
                  shippedDate,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10002));
    // 出庫日が未来日の場合
    } else if (!XxcmnUtility.chkCompareDate(2, currentDate, shippedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
    }
// 2019-09-05 Y.Shoji ADD START
    // 有償支給年月(返品)必須チェック
    String sikyuReturnDateStr = (String)row.getAttribute("SikyuReturnDate");
    if (XxcmnUtility.isBlankOrNull(sikyuReturnDateStr))
    {
      exceptions.add( new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  vo.getName(),
                  row.getKey(),
                  "SikyuReturnDate",
                  sikyuReturnDateStr,
                  XxcmnConstants.APPL_XXPO,
                  XxpoConstants.XXPO10002));
    // 有償支給年月(返品)桁数チェック
    // 有償支給年月(返品)数字型チェック
    // 有償支給年月(返品)'/'チェック
    } else if ( (sikyuReturnDateStr.length() != 7)
            || !(Character.isDigit(sikyuReturnDateStr.charAt(0)))
            || !(Character.isDigit(sikyuReturnDateStr.charAt(1)))
            || !(Character.isDigit(sikyuReturnDateStr.charAt(2)))
            || !(Character.isDigit(sikyuReturnDateStr.charAt(3)))
            || !(sikyuReturnDateStr.substring(4 ,5).equals(XxpoConstants.SLASH))
            || !(Character.isDigit(sikyuReturnDateStr.charAt(5)))
            || !(Character.isDigit(sikyuReturnDateStr.charAt(6))))
    {
        exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "SikyuReturnDate",
                            sikyuReturnDateStr,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO40049));
    } else{      
      // 有償支給年月(返品)の日付形式（yyyy/MM）のチェック
      SimpleDateFormat sdf = new SimpleDateFormat("yyyy/MM");
      sdf.setLenient(false);
      try {
        sdf.parse(sikyuReturnDateStr);
        Date sikyuReturnDate = XxcmnUtility.dateValueOra(sikyuReturnDateStr);
        // 有償支給年月(返品)が出庫日より未来日の場合
        if (!XxcmnUtility.chkCompareDate(2, shippedDate, sikyuReturnDate))
        {
          exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "SikyuReturnDate",
                              sikyuReturnDateStr,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10244));
        }
      } catch (Exception e)
      {
        exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "SikyuReturnDate",
                            sikyuReturnDateStr,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO40049));
      }
    }
// 2019-09-05 Y.Shoji ADD END
  } // chkNext

  /***************************************************************************
   * 適用処理のチェックを行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkOrderLine(
    String exeType
  ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納List

    // 支給返品作成ヘッダVO取得
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate");  // 出庫日
    if (XxpoUtility.chkStockClose(getOADBTransaction(),shippedDate)) 
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

    // 支給返品要約検索VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId");  // 代表価格表ID
    String listIdVendor = (String)hdrRow.getAttribute("PriceList");          // 取引先価格表ID    

    // 処理対象を取得します。
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();

    // 適用日(入庫日)の設定(返品の場合、入庫日=出庫日)
    Date arrivalDate = shippedDate;

    // 更新行取得
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((updRows != null) || (updRows.length > 0))
    {
      OARow updRow = null;

      for (int i = 0; i < updRows.length; i++) 
      {
        // i番目の行を取得
        updRow = (OARow)updRows[i];
        // 更新チェック処理
        chkOrderLineUpd(hdrRow, vo, updRow, exceptions);

        Number invItemId = (Number)updRow.getAttribute("InvItemId"); // INV品目ID
        String itemNo = (String)updRow.getAttribute("ItemNo");       // 品目No
        String dbItemNo = (String)updRow.getAttribute("DbItemNo");   // 品目No(DB)
        String unitPrice = (String)updRow.getAttribute("UnitPrice"); // 単価
        String reqQuantity = (String)updRow.getAttribute("ReqQuantity");  // 依頼数

        // エラーがない場合
        if (exceptions.size() == 0) {
          // 単価が未入力での場合
          if (XxcmnUtility.isBlankOrNull(unitPrice)) 
          {
            // 単価導出処理
            Number unitPriceNum = XxpoUtility.getUnitPrice(
                                         getOADBTransaction(),
                                         invItemId,
                                         listIdVendor,
                                         listIdRepresent,
                                         arrivalDate,
                                         itemNo);

            // 取得できなかった場合
            if (XxcmnUtility.isBlankOrNull(unitPriceNum)) 
            {
              exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          vo.getName(),
                          updRow.getKey(),
                          "ItemNo",
                          itemNo,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10201));
            // 取得できた場合
            } else 
            {
              updRow.setAttribute("UnitPriceNum", unitPriceNum);
            }
          // 単価が入力されている場合
          } else 
          {
            updRow.setAttribute("UnitPriceNum", unitPrice);
          }
          // 合計重量・合計容積の算出
          HashMap retMap = XxpoUtility.calcTotalValue(getOADBTransaction(),
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
                                  updRow.getKey(),
                                  "ItemNo",
                                  itemNo,
                                  XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN05002,
                                  tokens));
          } else 
          {
            // 重量、容積にセット
            updRow.setAttribute("Weight", (String)retMap.get("sumWeight"));
            updRow.setAttribute("Capacity", (String)retMap.get("sumCapacity"));
          }
        }
      }
    }

    // 挿入行取得
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0) )
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++) 
      {
        // i番目の行を取得
        insRow = (OARow)insRows[i];
        String itemNo = (String)insRow.getAttribute("ItemNo");  // 品目No
        String reqQuantity = (String)insRow.getAttribute("ReqQuantity");  // 依頼数
        // 挿入行チェック処理
        if (!chkOrderLineIns(hdrRow, vo, insRow, exceptions, exeType))
        {
          String unitPrice = (String)insRow.getAttribute("UnitPrice");  // 単価          
          // 単価が未入力の場合、単価導出を行う。
          if (XxcmnUtility.isBlankOrNull(unitPrice)) 
          {
            // 挿入行チェック処理でエラーにならなかった場合、単価導出
            Number invItemId = (Number)insRow.getAttribute("InvItemId");  // INV品目ID

            // 単価導出処理
            Number unitPriceNum = XxpoUtility.getUnitPrice(
                                         getOADBTransaction(),
                                         invItemId,
                                         listIdVendor,
                                         listIdRepresent,
                                         arrivalDate,
                                         itemNo);
            // 取得できなかった場合
            if (XxcmnUtility.isBlankOrNull(unitPriceNum)) 
            {
              exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          vo.getName(),
                          insRow.getKey(),
                          "ItemNo",
                          itemNo,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10201));
            // 取得できた場合
            } else 
            {
              insRow.setAttribute("UnitPriceNum", unitPriceNum);
            }
          // 単価が入力されている場合
          } else 
          {
            insRow.setAttribute("UnitPriceNum", unitPrice);
          }

          // 合計重量・合計容積の導出
          HashMap retMap = XxpoUtility.calcTotalValue(getOADBTransaction(),
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
                                  insRow.getKey(),
                                  "ItemNo",
                                  itemNo,
                                  XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN05002,
                                  tokens));
          } else
          {
            // 重量、容積にセット
            insRow.setAttribute("Weight",   (String)retMap.get("sumWeight"));
            insRow.setAttribute("Capacity", (String)retMap.get("sumCapacity"));
          }
        }
      }
    }

    // エラーがあった場合にエラーをスローします。
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
   ***************************************************************************
   */
  public void chkOrderLineUpd(
    OARow hdrRow,
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  )
  {
    // 情報を取得
    Object orderLineNum = row.getAttribute("OrderLineNumber");  // 明細番号
    Object itemNo = row.getAttribute("ItemNo"); // 品目コード
    Object reqQuantity = row.getAttribute("ReqQuantity"); // 依頼数量
    Object unitPrice = row.getAttribute("UnitPrice"); // 単価

    // 必須チェック(品目コード)
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
    // 品目が入力されている場合、品目重複チェック
    } else 
    {
      Row[] chkRows = vo.getAllRowsInRange();
      // 明細VOにレコードが存在する場合のみ行う
      if ((chkRows != null) || (chkRows.length > 0)) 
      {
        OARow chkRow = null;
        for (int i = 0; i < chkRows.length; i++) 
        {
          // i番目の行を取得
          chkRow = (OARow)chkRows[i];
          // 品目重複チェック
          if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))  // 違う明細行
            &&(XxcmnUtility.isEquals(itemNo, chkRow.getAttribute("ItemNo"))))               // 同じ品目  
          {
              exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          vo.getName(),
                          row.getKey(),
                          "ItemNo",
                          itemNo,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10151));
              break;
          }
        }
      }
    }

    // 必須チェック(依頼数量)
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

    // 依頼数量が入力されている場合、数値チェック
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
      // 依頼数量が数値である場合、数量チェック
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
        }
      }
    }

    // 単価チェック
    if (!XxcmnUtility.isBlankOrNull(unitPrice)) 
    {
      // 数値チェック
      if (!XxcmnUtility.chkNumeric(unitPrice, 7, 2)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "UnitPrice",
                              unitPrice,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
      }
    }
  } // chkOrderLineUpd

  /***************************************************************************
   * 適用処理のチェックを行うメソッドです。(挿入用)
   * @return boolean - True:エラー有り  False:エラー無し
   * @param hdrRow - ヘッダ行オブジェクト
   * @param vo     - ビューオブジェクト
   * @param row    - 明細行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkOrderLineIns (
    OARow hdrRow,
    OAViewObject vo,
    OARow row,
    ArrayList exceptions,
    String exeType
  ) throws OAException
  {
    boolean errFlag = false;  // エラーフラグ

    // 情報を取得
    Object orderLineNum = row.getAttribute("OrderLineNumber");  // 明細番号
    Object itemNo = row.getAttribute("ItemNo");                 // 品目コード
    Object futaiCode = row.getAttribute("FutaiCode");           // 付帯コード
    Object reqQuantity = row.getAttribute("ReqQuantity");       // 依頼数量
    Object description = row.getAttribute("LineDescription");   // 備考
    Object unitPrice = row.getAttribute("UnitPrice");           // 単価
    // 明細行に何も入力されていない場合はTrueで終了
    if (XxcmnUtility.isBlankOrNull(itemNo)
      && XxcmnUtility.isBlankOrNull(futaiCode)
      && XxcmnUtility.isBlankOrNull(reqQuantity)
      && XxcmnUtility.isBlankOrNull(description)
      && XxcmnUtility.isBlankOrNull(unitPrice)
    ) 
    {
      return true;
    }

    // 必須チェック(品目コード)
    if (XxcmnUtility.isBlankOrNull(itemNo)
      && (   !XxcmnUtility.isBlankOrNull(futaiCode)
          || !XxcmnUtility.isBlankOrNull(reqQuantity)
          || !XxcmnUtility.isBlankOrNull(description)
          || !XxcmnUtility.isBlankOrNull(unitPrice))
       ) 
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

    // 品目が入力されている場合、重複チェック
    } else 
    {
      // チェック用全行取得
      Row[] chkRows = vo.getAllRowsInRange();
      // 明細件数がある場合
      if ((chkRows != null) || (chkRows.length > 0)) 
      {
        OARow chkRow = null;
        for (int i = 0; i < chkRows.length; i++) 
        {
          // i番目の行を取得
          chkRow = (OARow)chkRows[i];
          // 品目重複チェック
          if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))  // 違う明細行
            &&(XxcmnUtility.isEquals(itemNo, chkRow.getAttribute("ItemNo"))))               // 同じ品目  
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

    // 必須チェック(依頼数量)
    if (XxcmnUtility.isBlankOrNull(reqQuantity)
      && (  !XxcmnUtility.isBlankOrNull(itemNo)
         || !XxcmnUtility.isBlankOrNull(futaiCode)
         || !XxcmnUtility.isBlankOrNull(description)
         || !XxcmnUtility.isBlankOrNull(unitPrice))
        ) 
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

    // 依頼数量が入力されている場合、数値チェック
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

      // 依頼数量が数値である場合、数量チェック
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
    // 単価チェック
    if (!XxcmnUtility.isBlankOrNull(unitPrice)) 
    {
      // 数値チェック
      if (!XxcmnUtility.chkNumeric(unitPrice, 7, 2)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "UnitPrice",
                              unitPrice,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
        errFlag = true;
      }
    }
    return errFlag;
  } // chkOrderLineIns

  /***************************************************************************
   * 金額確定前チェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   ***************************************************************************
   */
    public void chkAmountFix(
      OAViewObject vo,
      OARow row,
      ArrayList exceptions
    )
    {
      // 在庫会計期間クローズチェック
      Date shippedDate = (Date)row.getAttribute("ShippedDate"); // 出庫日
      if (XxpoUtility.chkStockClose(
            getOADBTransaction(),
            shippedDate
           )
          ) 
      {
        // 出荷日の年月≦直近にクローズした在庫会計期間年月の場合はエラー。
        exceptions.add(
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,
            vo.getName(),
            row.getKey(),
            "ShippedDate",
            shippedDate,
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10119
          )
        );
      }

      // ステータスチェック
      String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
      if(!XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
      {
        // ステータスが出荷実績計上済みではない場合はエラー。
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "TransStatus",
                              transStatus,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10145));
      }

      // 金額確定済みチェック
      String fixClass = (String)row.getAttribute("FixClass"); // 金額確定区分
      if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
      {
        // エラーメッセージは発生区分欄に表示
        Number orderType = (Number)row.getAttribute("OrderTypeId"); // 発生区分
        // 金額確定済み(1)の場合はエラー。
        exceptions.add(
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,
            vo.getName(),
            row.getKey(),
            "OrderTypeId",
            orderType,
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10125
          )
        );
      }
    } // chkAmountFix

  /***************************************************************************
   * 受注ヘッダアドオン、受注明細アドオンのロックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
    public void chkLockAndExclusive(
      OAViewObject vo,
      OARow row
    ) throws OAException
    {

      //ロック対象を取得します。
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); //受注ヘッダアドオンID
      //受注タイプIDを取得します。
      Number orderType = (Number)row.getAttribute("OrderTypeId");       //発生区分ID

      //ロック取得共通メソッドを実行します。
      if (!XxpoUtility.getXxwshOrderLock(getOADBTransaction(), orderHeaderId))
      //戻り値がfalse(エラー)の場合        
      {
        //ロールバックします。
        XxpoUtility.rollBack(getOADBTransaction());

        //エラーメッセージ 
        throw new OAAttrValException(
          OAAttrValException.TYP_VIEW_OBJECT,
          vo.getName(),
          row.getKey(),
          "OrderTypeId",
          orderType,
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10138
        );
      }

      //VOの最終更新日を取得します。
      String xohaLastUpdateDate = (String)row.getAttribute("XohaLastUpdateDate"); //最終更新日(受注ヘッダ)
      String xolaLastUpdateDate = (String)row.getAttribute("XolaLastUpdateDate"); //最終更新日(受注明細)

      //排他チェック(VOの最終更新日とDBの最終更新日を比較)を行います。
      if (!XxpoUtility.chkExclusiveXxwshOrder(
            getOADBTransaction(),
            orderHeaderId,
            xohaLastUpdateDate,
            xolaLastUpdateDate
            )
          )
      {
        //ロールバックします。
        XxpoUtility.rollBack(getOADBTransaction());

        //排他エラーメッセージ
        throw new OAAttrValException(
          OAAttrValException.TYP_VIEW_OBJECT,
          vo.getName(),
          row.getKey(),
          "OrderTypeId",
          orderType,
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10147
        );
      }
    } //chkLockAndExclusive

  /***************************************************************************
   * ページングの際にチェックボックスをOFFにします。
   * @throws OAException - OA例外
   ***************************************************************************
   */
    public void checkBoxOff() throws OAException
    {
      //処理対象を取得します。
      OAViewObject vo = getXxpoProvisionRtnSumResultVO1();
      Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

      //未選択チェックを行います。
      if ((rows != null) || (rows.length != 0))
      {
        OARow row = null;
        for (int i = 0; i < rows.length; i++)
        {
          //i番目の行を取得
          row = (OARow)rows[i];
          row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
        }
      }
    } //checkBoxOff

  /***************************************************************************
   * 削除処理のチェックを行うメソッドです。
   * @param vo     - ビューオブジェクト
   * @param hdrRow - ヘッダ行オブジェクト
   * @param row    - 明細行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkOrderLineDel(
    OAViewObject vo,
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
   * 支給返品作成ヘッダ画面の項目を全てFALSEにするメソッドです。
   * @param prow    - PVO行クラス
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void handleEventAllOnHdr(
    OARow prow
  ) throws OAException
  {
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.FALSE); // 支給取消ボタン
    prow.setAttribute("OrderTypeReadOnly"            , Boolean.FALSE); // 発生区分
    prow.setAttribute("WeightCapacityReadOnly"       , Boolean.FALSE); // 重量容積区分
    prow.setAttribute("ReqDeptReadOnly"              , Boolean.FALSE); // 依頼部署
    prow.setAttribute("VendorReadOnly"               , Boolean.FALSE); // 取引先
    prow.setAttribute("ShipToReadOnly"               , Boolean.FALSE); // 配送先
    prow.setAttribute("ShipWhseReadOnly"             , Boolean.FALSE); // 出庫倉庫
    prow.setAttribute("FreightCarrierReadOnly"       , Boolean.FALSE); // 運送業者
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.FALSE); // 出庫日
// 2019-09-05 Y.Shoji ADD START
    prow.setAttribute("SikyuReturnDateReadOnly"      , Boolean.FALSE); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END
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
   * 支給返品作成ヘッダ画面の項目を全てTRUEにするメソッドです。
   * @param prow    - PVO行クラス
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void handleEventAllOffHdr(
    OARow prow
    ) throws OAException
  {
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.TRUE); // 支給取消ボタン
    prow.setAttribute("OrderTypeReadOnly"            , Boolean.TRUE); // 発生区分
    prow.setAttribute("WeightCapacityReadOnly"       , Boolean.TRUE); // 重量容積区分
    prow.setAttribute("ReqDeptReadOnly"              , Boolean.TRUE); // 依頼部署
    prow.setAttribute("VendorReadOnly"               , Boolean.TRUE); // 取引先
    prow.setAttribute("ShipToReadOnly"               , Boolean.TRUE); // 配送先
    prow.setAttribute("ShipWhseReadOnly"             , Boolean.TRUE); // 出庫倉庫
    prow.setAttribute("FreightCarrierReadOnly"       , Boolean.TRUE); // 運送業者
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.TRUE); // 出庫日
// 2019-09-05 Y.Shoji ADD START
    prow.setAttribute("SikyuReturnDateReadOnly"      , Boolean.TRUE); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END
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
   * 支給返品作成ヘッダ画面の新規時の項目制御処理を行うメソッドです。
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
    prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン
    prow.setAttribute("FixReadOnly", Boolean.TRUE);         // 金額確定チェックボックス
  } // handleEventInsHdr

  /***************************************************************************
   * 支給返品作成ヘッダ画面の更新時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ ※支給返品では未使用
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
    // ステータスを取得
    String transStatus = (String)row.getAttribute("TransStatus");

    // ステータスが「入力中」の場合
    if (XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      prow.setAttribute("ProvCancelBtnReject", Boolean.FALSE); // 支給取消ボタン
      prow.setAttribute("FixReadOnly", Boolean.TRUE);         // 金額確定チェックボックス

      // 受領タイプを取得
      String rcvType = (String)row.getAttribute("RcvType");
      // 受領タイプが「一部実績有り」の場合
      if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
      {
        prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン
      }

    // ステータスが「出荷実績計上済」の場合
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus))
    {
      // 「出荷実績計上済」項目制御
      prow.setAttribute("OrderTypeReadOnly", Boolean.TRUE);   // 発生区分
      prow.setAttribute("ReqDeptReadOnly", Boolean.TRUE);     // 依頼部署
      prow.setAttribute("VendorReadOnly", Boolean.TRUE);      // 取引先
      prow.setAttribute("ShipToReadOnly", Boolean.TRUE);      // 配送先
      prow.setAttribute("ShipWhseReadOnly", Boolean.TRUE);    // 出庫倉庫
      prow.setAttribute("ShippedDateReadOnly", Boolean.TRUE); // 出庫日
// 2019-09-05 Y.Shoji ADD START
      prow.setAttribute("SikyuReturnDateReadOnly", Boolean.TRUE); // 有償支給年月(返品)
// 2019-09-05 Y.Shoji ADD END
      prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // 支給取消ボタン

      // 金額確定フラグを取得
      String fixClass = (String)row.getAttribute("FixClass");
      // 「金額未確定」項目制御
      if (XxpoConstants.FIX_CLASS_OFF.equals(fixClass)) 
      {
        prow.setAttribute("ShippingInstructionsReadOnly", Boolean.FALSE);    // 摘要
      // 「金額確定済」項目制御
      } else 
      {
        prow.setAttribute("ShippingInstructionsReadOnly", Boolean.TRUE);    // 摘要
      }
      prow.setAttribute("FixReadOnly", Boolean.FALSE);         // 金額確定チェックボックス
    }
  } // handleEventUpdHdr

  /***************************************************************************
   * 支給返品作成明細画面の項目を全てFALSEにするメソッドです。
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
    // ステータスを取得
    String transStatus = (String)hdrRow.getAttribute("TransStatus");

    // 入力中の場合
    if (XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      prow.setAttribute("AddRowBtnRender", Boolean.TRUE); // 行挿入ボタン

    // 出荷実績計上済の場合
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
    {
      prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // 行挿入ボタン
    }
  } // handleEventUpdLine


  /***************************************************************************
   * 変更に関する警告をセットします。
   ***************************************************************************
   */
  public void doWarnAboutChanges()
  {
    // 支給指示作成ヘッダVO取得
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow  = (OARow)hdrVo.first();

    // いづれかの項目に変更があった場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("OrderTypeId"),          hdrRow.getAttribute("DbOrderTypeId"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("WeightCapacityClass"),  hdrRow.getAttribute("DbWeightCapacityClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ReqDeptCode"),          hdrRow.getAttribute("DbReqDeptCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("InstDeptCode"),         hdrRow.getAttribute("DbInstDeptCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("VendorCode"),           hdrRow.getAttribute("DbVendorCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipToCode"),           hdrRow.getAttribute("DbShipToCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipWhseCode"),         hdrRow.getAttribute("DbShipWhseCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightCarrierCode"),   hdrRow.getAttribute("DbFreightCarrierCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          hdrRow.getAttribute("DbShippedDate"))
// 2019-09-05 Y.Shoji ADD START
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("SikyuReturnDate"),      hdrRow.getAttribute("DbSikyuReturnDate"))
// 2019-09-05 Y.Shoji ADD END
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"),          hdrRow.getAttribute("DbArrivalDate"))
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
      XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();

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
           || !XxcmnUtility.isEquals(row.getAttribute("UnitPriceNum"),    row.getAttribute("DbUnitPriceNum"))
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

//  ---------------------------------------------------------------
//  ---    Default Method
//  ---------------------------------------------------------------
  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo440007j.server", "XxpoProvisionRtnSummaryAMLocal");
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
   * Container's getter for OrderTypeVO1
   */
  public OAViewObjectImpl getOrderTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderTypeVO1");
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
   * Container's getter for NotifStatusVO1
   */
  public OAViewObjectImpl getNotifStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("NotifStatusVO1");
  }


  /**
   * 
   * Container's getter for OrderType2VO1
   */
  public OAViewObjectImpl getOrderType2VO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderType2VO1");
  }

  /**
   * 
   * Container's getter for TransStatus2VO1
   */
  public OAViewObjectImpl getTransStatus2VO1()
  {
    return (OAViewObjectImpl)findViewObject("TransStatus2VO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRtnSumResultVO1
   */
  public XxpoProvisionRtnSumResultVOImpl getXxpoProvisionRtnSumResultVO1()
  {
    return (XxpoProvisionRtnSumResultVOImpl)findViewObject("XxpoProvisionRtnSumResultVO1");
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
   * Container's getter for XxpoProvisionRtnMakeHeaderVO1
   */
  public XxpoProvisionRtnMakeHeaderVOImpl getXxpoProvisionRtnMakeHeaderVO1()
  {
    return (XxpoProvisionRtnMakeHeaderVOImpl)findViewObject("XxpoProvisionRtnMakeHeaderVO1");
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
   * Container's getter for FreightVO1
   */
  public OAViewObjectImpl getFreightVO1()
  {
    return (OAViewObjectImpl)findViewObject("FreightVO1");
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
   * Container's getter for XxpoProvisionRtnMakeHeaderPVO1
   */
  public XxpoProvisionRtnMakeHeaderPVOImpl getXxpoProvisionRtnMakeHeaderPVO1()
  {
    return (XxpoProvisionRtnMakeHeaderPVOImpl)findViewObject("XxpoProvisionRtnMakeHeaderPVO1");
  }


  /**
   * 
   * Container's getter for XxpoProvisionRtnMakeLinePVO1
   */
  public XxpoProvisionRtnMakeLinePVOImpl getXxpoProvisionRtnMakeLinePVO1()
  {
    return (XxpoProvisionRtnMakeLinePVOImpl)findViewObject("XxpoProvisionRtnMakeLinePVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRtnMakeTotalVO1
   */
  public XxpoProvisionRtnMakeTotalVOImpl getXxpoProvisionRtnMakeTotalVO1()
  {
    return (XxpoProvisionRtnMakeTotalVOImpl)findViewObject("XxpoProvisionRtnMakeTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRtnMakeLineVO1
   */
  public XxpoProvisionRtnMakeLineVOImpl getXxpoProvisionRtnMakeLineVO1()
  {
    return (XxpoProvisionRtnMakeLineVOImpl)findViewObject("XxpoProvisionRtnMakeLineVO1");
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