/*============================================================================
* ファイル名 : XxpoShipToResultAMImpl
* 概要説明   : 入庫実績要約アプリケーションモジュール
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  新藤義勝     新規作成
* 2008-07-01 1.1  二瓶大輔     内部変更要求対応#147,#149,ST不具合#248対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;

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
 * 入庫実績要約画面のアプリケーションモジュールクラスです。
 * @author  ORACLE 新藤 義勝
 * @version 1.1
 ***************************************************************************
 */
public class XxpoShipToResultAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShipToResultAMImpl()
  {
  }

  /***************************************************************************
   * 入庫実績要約画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   ***************************************************************************
   */
  public void initializeList(
    String exeType
    )
  {
    // 支給依頼要約検索VO
    XxpoProvSearchVOImpl vo = getXxpoProvSearchVO1();
    // 1行もない場合、空行作成
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("ExeType", exeType);

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
      row.setNewRowState(OARow.STATUS_INITIALIZED);

      // 起動タイプが「32：パッカー･外注工場用」の場合
      if (XxpoConstants.EXE_TYPE_32.equals(exeType)) 
      {
        // ユーザー情報取得 
        HashMap userInfo = XxpoUtility.getUserData(getOADBTransaction());
        // 仕入先に値を設定
        row.setAttribute("VendorId",   userInfo.get("VendorId"));
        row.setAttribute("VendorCode", userInfo.get("VendorCode"));
        row.setAttribute("VendorName", userInfo.get("VendorName"));

      }
    }
  } // initializeList
  
  /***************************************************************************
   * 入庫実績要約画面の検索処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchList(
   String exeType
  ) throws OAException
  {
    // 入庫実績検索VO取得
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
    shParams.put("exeType", exeType);                                    // 起動タイプ
    // 入庫実績結果VO取得
     XxpoShipToResultVOImpl vo = getXxpoShipToResultVO1();
    // 検索を実行します。
    vo.initQuery(shParams);

  } // doSearchList

  /***************************************************************************
   * 入庫実績要約画面の全数入庫処理前の未選択チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkBeforeDecision() throws OAException
  {
    // 入庫実績結果VO取得
    OAViewObject vo = getXxpoShipToResultVO1();
    
    // 選択されたレコードを取得
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // 未選択チェックを行います。
    chkNonChoice(rows);
    
  } // chkBeforeDecision

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
   * 入庫実績要約画面の全数入庫処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doDecisionList(
   String exeType
  ) throws OAException
  {   
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag      = false; // 実行フラグ

    // 処理対象を取得します。
    OAViewObject vo = getXxpoShipToResultVO1();
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      // エラーチェック
      chkInputAll(vo, row, exceptions);

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
      if(chkLockAndExclusive(vo, row))
      {
        // 全数入庫の実績登録処理
        Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
        Date arriveDate = (Date)row.getAttribute("ArrivalDate");
        if((XxpoUtility.updateOrderExecute(getOADBTransaction(),
                                orderHeader,
                                XxpoConstants.REC_TYPE_30,
                                arriveDate)))
        {
          exeFlag = true;
        } else
        {
          //トークン生成
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                        "全数処理") };
          // エラーメッセージ出力
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                 XxcmnConstants.XXCMN05002, 
                                 tokens);
        }
      }
    }    
    // 実行された場合
    if (exeFlag) 
    {
      // コミット発行
      XxpoUtility.commit(getOADBTransaction());
      // 再検索を行います。
      doSearchList(exeType);
      // 処理成功メッセージ出力
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_ALL_SHIP_TO);

    } 
  } // doDecisionList

  /***************************************************************************
   * ロック・排他処理を行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean chkLockAndExclusive(
    OAViewObject vo,
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
     // 排他チェックOK
    } else
    {
      return true;
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * 依頼Noごとにチェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkInputAll(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {

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

    // 実績未入力チェックを行います。
     Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
    if(!XxpoUtility.chkOrderResult(getOADBTransaction(),
                                   orderHeader,
                                   XxpoConstants.REC_TYPE_30))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "OrderHeaderId",
                            orderHeader,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10130)); 

    }

    // ロットステータスチェックを行います。
    String requestNo = (String)row.getAttribute("RequestNo");
    if(!(XxpoUtility.chkLotStatus(getOADBTransaction(),
                                  requestNo)))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "RequestNo",
                            requestNo,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10210));
    }
  } // chkInputAll

 
  /***************************************************************************
   * ページングの際にチェックボックスをOFFにします。
   ***************************************************************************
   */
  public void checkBoxOff()
  {
    // 処理対象を取得します。
    OAViewObject vo = getXxpoShipToResultVO1();
    Row[] rows      = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // チェックボックスをOFFにします。
    if((rows != null) || (rows.length != 0))
    {
      OARow row = null;
      for(int i=0;i<rows.length;i++)
      {
        //i番目の行を取得
        row = (OARow)rows[i];
        row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * 入庫実績入力ヘッダ画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param reqNo   - 依頼No
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    )
  {
     // 入庫実績作成ヘッダPVO
      XxpoShipToHeaderPVOImpl pvo = getXxpoShipToHeaderPVO1(); 
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

      // 依頼Noで検索を実行
      doSearchHdr(reqNo);

      // 入庫実績入力ヘッダVO取得
      XxpoShipToHeaderVOImpl vo = getXxpoShipToHeaderVO1();
      OARow row = (OARow)vo.first();
      // 更新時項目制御
      handleEventUpdHdr(exeType, prow, row);
      // 明細行の検索
      doSearchLine();

  } // initializeHdr  

  /***************************************************************************
   * 入庫実績入力ヘッダ画面の検索処理を行うメソッドです。
   * @param  reqNo - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */ 
  public void doSearchHdr(
    String reqNo
    ) throws OAException
  {
     // 入庫実績作成ヘッダVO取得
    XxpoShipToHeaderVOImpl vo = getXxpoShipToHeaderVO1();
    // 検索を実行します。
    vo.initQuery(reqNo);
    vo.first();
    // 対象データを取得できない場合エラー
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // 入庫実績作成PVO
      XxpoShipToHeaderPVOImpl pvo = getXxpoShipToHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // 参照のみ
      handleEventAllOffHdr(prow);
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10500);

    }
  } // doSearchHdr 

  /***************************************************************************
   * 入庫実績入力ヘッダ画面の次へ処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doNext() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List
    boolean exeFlag = false; // 実行フラグ
    
    // 入庫実績作成ヘッダVO取得
    OAViewObject vo = getXxpoShipToHeaderVO1();
    OARow row   = (OARow)vo.first();
    // 入庫日必須入力チェック
    chkArrival(vo, row, exceptions);

  } // doNext

  /***************************************************************************
   * 入庫実績入力明細画面の初期化処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param reqNo   - 依頼No
   ***************************************************************************
   */
  public void initializeLine(
    String exeType,
    String reqNo)     
  {
    // 入庫実績入力明細PVO
    XxpoShipToLinePVOImpl pvo = getXxpoShipToLinePVO1();
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

    }

    // 支給指示作成ヘッダVO取得
    OAViewObject vo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)vo.first();
    String fixClass = (String)hdrRow.getAttribute("FixClass");    // 金額確定済区分
    // 金額確定区分が「金額確定済」の場合
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // 押下可
      prow.setAttribute("ApplyBtnReject", Boolean.TRUE);
    } else
    {
      // 押下不可
      prow.setAttribute("ApplyBtnReject", Boolean.FALSE);
    }
  } // initializeLine

  /***************************************************************************
   * 入庫実績入力明細画面の検索処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
   public void doSearchLine(
    ) throws OAException
  {
    // 入庫実績入力ヘッダVO取得
    XxpoShipToHeaderVOImpl hdrVo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();     
    // 受注ヘッダアドオンIDを取得します。
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // 受注ヘッダアドオンID

    // 入庫実績入力明細VO取得
    XxpoShipToLineVOImpl vo = getXxpoShipToLineVO1();
    // 検索を実行します。
    vo.initQuery(orderHeaderId);

    // 入庫実績作成合計VO取得
    XxpoShipToTotalVOImpl totalVo = getXxpoShipToTotalVO1();
    // 検索を実行します。
    totalVo.initQuery(orderHeaderId); 

  } // doSearchLine

  /***************************************************************************
   * 次へボタン押下時の入庫日必須入力チェックを行うメソッドです。
   * @param vo - ビューオブジェクト
   * @param row - 行オブジェクト
   * @param exceptions - エラーメッセージ格納用配列
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkArrival(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // 入庫日
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate");
    // 出庫日
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // システム日付を取得
    Date currentDate = getOADBTransaction().getCurrentDBDate();
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
    // 入庫日が未来日の場合
    } else if (!XxcmnUtility.chkCompareDate(2, currentDate, arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
    // 出庫日＞入庫日の場合
    } else if (XxcmnUtility.chkCompareDate(1, shippedDate, arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10249));

    } 
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkArrival

  /***************************************************************************
   * 入庫実績作成ヘッダ画面の項目を全てFALSEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOnHdr(OARow prow)
  {
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.FALSE); // 入庫日
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.FALSE); // 摘要

  } // handleEventAllOnHdr

  /***************************************************************************
   * 入庫実績作成ヘッダ画面の項目を全てTRUEにするメソッドです。
   * @param prow    - PVO行クラス
   ***************************************************************************
   */
  public void handleEventAllOffHdr(OARow prow)
  {
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.TRUE); // 入庫日
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.TRUE); // 摘要

  } // handleEventAllOffHdr

  /***************************************************************************
   * 入庫実績入力ヘッダ画面の更新時の項目制御処理を行うメソッドです。
   * @param exeType - 起動タイプ
   * @param prow    - PVO行クラス
   * @param row     - VO行クラス
   ***************************************************************************
   */
  public void handleEventUpdHdr(
    String exeType,
    OARow prow,
    OARow row
    )
  {
    // 各種情報取得
    String notifStatus = (String)row.getAttribute("NotifStatus"); // 通知ステータス
    String transStatus = (String)row.getAttribute("TransStatus"); // ステータス
    String fixClass    = (String)row.getAttribute("FixClass");    // 金額確定済区分

    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // 参照のみ
      handleEventAllOffHdr(prow);
    } else 
    {
      // 通知ステータスが「確定通知済」の場合
      if ((XxpoConstants.NOTIF_STATUS_KTZ.equals(notifStatus))
       && (   XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus) 
           || XxpoConstants.PROV_STATUS_SJK.equals(transStatus)))
      {
        // 入力可
        handleEventAllOnHdr(prow);
        String freightClass = (String)row.getAttribute("FreightChargeClass"); // 運賃区分
        // 運賃区分が「ON」の場合は入庫日制御不可
        if (XxcmnConstants.STRING_ONE.equals(freightClass)) 
        {
          prow.setAttribute("ArrivalDateReadOnly", Boolean.TRUE);  
        }
      } else
      {
        // 参照のみ
        handleEventAllOffHdr(prow);
      }
    }
  } //  handleEventUpdHdr

  /***************************************************************************
   * 入庫実績入力明細画面の適用処理を行うメソッドです。
   * @param  exeType - 起動タイプ
   * @return  HashMap - 戻り値群
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
    ) throws OAException
  {
    // チェック処理
    chkOrderLine(exeType);

    // 支給指示作成ヘッダVO取得
    XxpoShipToHeaderVOImpl hdrVo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // 新規フラグ
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // 依頼No
    String tokenName = null;

    // 新規フラグが「N：更新」の場合
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // 排他チェック
      chkLockAndExclusive(hdrVo, hdrRow);
      tokenName = XxpoConstants.TOKEN_NAME_UPD;
    }

    // 更新処理
    if (doUpdate(newFlag, hdrRow, exeType)) 
    {
      // コミット処理
      XxpoUtility.commit(getOADBTransaction());

      if (XxpoConstants.TOKEN_NAME_UPD.equals(tokenName)) 
      {
        // 初期化
        initializeHdr(exeType, reqNo);
        initializeLine(exeType, reqNo);
      }
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
   * 適用処理のチェックを行うメソッドです。
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkOrderLine(String exeType) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // エラーメッセージ格納用List

    // 入庫実績入力ヘッダVO取得
    XxpoShipToHeaderVOImpl hdrVo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

    // 在庫会計期間クローズチェックを行います。
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // 出庫日
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

    // 単価導出可否を判断します。
    boolean priceFlag = false;
    Date arrivalDate = (Date)hdrRow.getAttribute("ArrivalDate"); // 入庫日
    // 入庫日が変更されている場合
    if (!XxcmnUtility.isEquals(arrivalDate, hdrRow.getAttribute("DbArrivalDate")))
    {
       priceFlag = true;  
    }

    OAViewObject svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId"); // 代表価格表      
    String listIdVendor    = (String)hdrRow.getAttribute("PriceList");    // 取引先価格表ID

    // 処理対象を取得します。
    XxpoShipToLineVOImpl vo = getXxpoShipToLineVO1();
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
        Number invItemId = (Number)updRow.getAttribute("InvItemId"); // INV品目ID
        String itemNo    = (String)updRow.getAttribute("ItemNo");    // 品目No
        String dbItemNo  = (String)updRow.getAttribute("DbItemNo");  // 品目No(DB)
        
        // 単価導出フラグがtrue
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
                                  updRow.getKey(),
                                  "ItemNo",
                                  itemNo,
                                  XxcmnConstants.APPL_XXPO, 
                                  XxpoConstants.XXPO10201));

          } else
          {
            updRow.setAttribute("UnitPriceNum", unitPrice);

          }
        }
      }
    }
    // エラーがあった場合エラーをスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    } 
  } //chkOrderLine   

  /***************************************************************************
   * 更新処理を行うメソッドです。
   * @param newFlag - 新規フラグ N:更新
   * @param hdrRow  - ヘッダ行オブジェクト
   * @param exeType - 起動タイプ
   * @throws OAException - OA例外
   * @return updateFlag - 更新フラグ true:更新あり false:更新なし
   ***************************************************************************
   */
  public boolean doUpdate(
    String newFlag,
    OARow hdrRow,
    String exeType
    ) throws OAException
  {

    // 更新フラグ
    boolean updateFlag = false;
    
    // 入庫実績入力明細VO
    XxpoShipToLineVOImpl vo = getXxpoShipToLineVO1();
    boolean lineExeFlag = false; // 明細実行フラグ
    boolean hdrExeFlag  = false; // ヘッダ実行フラグ
    
     // 明細更新行取得
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    
    if ((updRows != null) || (updRows.length > 0)) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++)
      {
        // i番目の行を取得
        updRow = (OARow)updRows[i];
        // 備考が変更された場合
        if (!XxcmnUtility.isEquals(updRow.getAttribute("LineDescription"), updRow.getAttribute("DbLineDescription")))
        {
          // 更新処理
          updateOrderLine(updRow);
          // 明細実行フラグをtrueに変更
          lineExeFlag = true;

        }        
      }
    }

      // ヘッダ更新の場合
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // 入庫日または摘要が変更された場合
      if ((!XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"), hdrRow.getAttribute("DbArrivalDate")))
      ||   !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions")))
      {
        // 更新処理
        updateOrderHdr(hdrRow);
        // 移動ロット詳細の更新
        updateMovLotDetails(hdrRow);
        // ヘッダ実行フラグをtrueに変更
        hdrExeFlag = true;
      }
    }  
    if (hdrExeFlag || lineExeFlag) 
    {
      updateFlag = true;
      return updateFlag;
    } else
    {
      return updateFlag;
    }  

  } // doUpdate 

  /*****************************************************************************
   * 受注明細アドオンのデータを更新します。
   * @param insRow - 挿入対象行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void updateOrderLine(
    OARow insRow
    ) throws OAException
  {
    String apiName      = "updateOrderLine";
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.unit_price        = :1 " ); // 単価
    sb.append("        ,xola.line_description  = :2 " ); // 備考
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID "); // 最終更新者
    sb.append("        ,xola.last_update_date  = SYSDATE "             ); // 最終更新日
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン
    sb.append("  WHERE  xola.order_line_id = :3 ; "); // 受注明細アドオンID
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // 情報を取得
      Number unitPrice       = (Number)insRow.getAttribute("UnitPriceNum");     // 単価
      String lineDescription = (String)insRow.getAttribute("LineDescription");  // 摘要
      Number orderLineId     = (Number)insRow.getAttribute("OrderLineId");      // 受注明細アドオンID

      // パラメータ設定(INパラメータ)
      cstmt.setInt(1, XxcmnUtility.intValue(unitPrice));            // 単価
      cstmt.setString(2, lineDescription);                          // 摘要     
      cstmt.setInt(3, XxcmnUtility.intValue(orderLineId));          // 受注明細アドオンID

      // PL/SQL実行
      cstmt.execute();

      // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine 

  /*****************************************************************************
   * 受注ヘッダアドオンのデータを更新します。
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
    sb.append("  SET    xoha.arrival_date                = :1 " ); // 着荷日
    sb.append("        ,xoha.shipping_instructions       = :2 " ); // 出荷指示
    sb.append("        ,xoha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // 最終更新者
    sb.append("        ,xoha.last_update_date      = SYSDATE "             ); // 最終更新日
    sb.append("        ,xoha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // 最終更新ログイン 
    sb.append("  WHERE  xoha.order_header_id = :3 ; ");   // 受注ヘッダアドオンID
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // 情報を取得
      Date   arrivalDate    = (Date)hdrRow.getAttribute("ArrivalDate");             // 入庫日
      String instructions   = (String)hdrRow.getAttribute("ShippingInstructions");  // 摘要
      Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId"); 

      // パラメータ設定(INパラメータ)
      cstmt.setDate(1, XxcmnUtility.dateValue(arrivalDate)); // 着荷日
      cstmt.setString(2, instructions);                      // 出荷指示
      cstmt.setInt(3, XxcmnUtility.intValue(orderHeaderId)); // 受注ヘッダアドオンID
     
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHdr  

  /*****************************************************************************
   * 移動ロット詳細のデータを更新します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void updateMovLotDetails(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "updateMovLotDetails";

    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxinv_mov_lot_details xmld ");
    sb.append("  SET   xmld.actual_date       = :1 " );                 // 実績日
    sb.append("       ,xmld.last_updated_by   = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("       ,xmld.last_update_date  = SYSDATE ");             // 最終更新日
    sb.append("       ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE xmld.mov_line_id IN ( SELECT xola.order_line_id  " ); // 明細ID
    sb.append("                              FROM   xxwsh_order_lines_all xola "); // 受注明細アドオン
    sb.append("                              WHERE  xola.order_header_id = :2 ");  // 受注ヘッダアドオンID
    sb.append("                            )  ");
    sb.append("  AND   xmld.record_type_code   = '30'    "); // レコードタイプ：入庫
    sb.append("  AND   xmld.document_type_code = '30' ;  "); // 文書タイプ：支給指示
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // 情報を取得
      Date   actualDate = (Date)hdrRow.getAttribute("ArrivalDate");      // 入庫日
      Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId");  // 受注ヘッダアドオンID

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));            // 出荷日
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));           // 受注ヘッダアドオンID
     
      //PL/SQL実行
      cstmt.execute();

    // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
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
                                XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // updateMovLotDetails 


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo442001j.server", "XxpoShipToResultAMLocal");
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
   * Container's getter for XxpoShipToHeaderPVO1
   */
  public XxpoShipToHeaderPVOImpl getXxpoShipToHeaderPVO1()
  {
    return (XxpoShipToHeaderPVOImpl)findViewObject("XxpoShipToHeaderPVO1");
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
   * Container's getter for XxpoShipToTotalVO1
   */
  public XxpoShipToTotalVOImpl getXxpoShipToTotalVO1()
  {
    return (XxpoShipToTotalVOImpl)findViewObject("XxpoShipToTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToLineVO1
   */
  public XxpoShipToLineVOImpl getXxpoShipToLineVO1()
  {
    return (XxpoShipToLineVOImpl)findViewObject("XxpoShipToLineVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToResultVO1
   */
  public XxpoShipToResultVOImpl getXxpoShipToResultVO1()
  {
    return (XxpoShipToResultVOImpl)findViewObject("XxpoShipToResultVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToHeaderVO1
   */
  public XxpoShipToHeaderVOImpl getXxpoShipToHeaderVO1()
  {
    return (XxpoShipToHeaderVOImpl)findViewObject("XxpoShipToHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToLinePVO1
   */
  public XxpoShipToLinePVOImpl getXxpoShipToLinePVO1()
  {
    return (XxpoShipToLinePVOImpl)findViewObject("XxpoShipToLinePVO1");
  }
}