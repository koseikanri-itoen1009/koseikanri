/*============================================================================
* ファイル名 : XxpoOrderReceiptAMImpl
* 概要説明   : 受入実績作成:受入実績作成アプリケーションモジュール
* バージョン : 1.13
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-04 1.0  吉元強樹     新規作成
* 2008-05-23 1.1  吉元強樹     内部課題#42、結合不具合ログ#1,2を対応
* 2008-06-11 1.2  吉元強樹     ST不具合ログ#72を対応
* 2008-06-26 1.3  北寒寺正夫   結合テスト指摘No02対応
* 2008-07-08 1.4  二瓶大輔     変更要求#91対応
* 2008-08-25 1.5  伊藤ひとみ   変更要求#205対応
* 2008-11-04 1.6  吉元強樹     統合指摘#546対応
* 2008-11-05 1.7  伊藤ひとみ   統合テスト指摘71,103,104対応
* 2008-12-05 1.8  伊藤ひとみ   本番障害#481対応
* 2009-01-16 1.9  吉元強樹     本番障害#1006対応
* 2009-01-27 1.10 吉元強樹     本番障害#1092対応
* 2009-03-11 1.11 飯田  甫     本番障害#1270対応
* 2009-05-12 1.12 吉元強樹     本番障害#1458対応
* 2011-06-01 1.13 窪和重       本番障害#1786対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.apps.fnd.common.MessageToken;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

/***************************************************************************
 * 受入実績作成:受入実績作成アプリケーションモジュールです。
 * @author  SCS 吉元 強樹
 * @version 1.11
 ***************************************************************************
 */
public class XxpoOrderReceiptAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderReceiptAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo310001j.server", "XxpoOrderReceiptAMLocal");
  }

  /***************************************************************************
   * (発注受入検索画面)初期化処理を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void initialize() throws OAException
  {
    // ***************************** //
    // * 発注受入:検索VO 空行取得  * //
    // ***************************** //
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();

    // 1行もない場合、空行作成
    if (!orderReceiptSerchVO.isPreparedForExecution())
    {
      orderReceiptSerchVO.setMaxFetchSize(0);
      orderReceiptSerchVO.insertRow(orderReceiptSerchVO.createRow());
      // 1行目を取得
      OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();
      // キーに値をセット
      orderReceiptSerchVORow.setNewRowState(Row.STATUS_INITIALIZED);
      orderReceiptSerchVORow.setAttribute("RowKey", new Number(1));
    }
       
    // ************************************ //
    // * 納入先設定処理(外部ユーザのみ)   * //
    // ************************************ //
    setLocationCode();
    
  } // initialize

  /***************************************************************************
   * (発注受入検索画面)納入先を設定するメソッドです。(外部ユーザのみ)
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void setLocationCode() throws OAException
  {

/*
    // *************************** //
    // * ユーザー情報取得        * //
    // *************************** //
    getUserData();
*/
    // 発注受入検索VO取得
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();

    // 1行目を取得
    OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();

// 20080528 add yoshimoto Start
    // *************************** //
    // * ユーザー情報取得        * //
    // *************************** //
    getUserData(orderReceiptSerchVORow);
// 20080528 add yoshimoto End

    // 従業員区分を取得
    String peopleCode = (String)orderReceiptSerchVORow.getAttribute("PeopleCode"); // 従業員区分

    // 従業員区分が2:外部の場合
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {

      // 外部ユーザの自倉庫のカウントを取得
      int warehouseCount = getWarehouseCount();

      // 自倉庫のカウントが1の場合
      if (warehouseCount == 1) 
      {
        // *********************** //
        // * 自倉庫情報を取得    * //
        // *********************** //
        HashMap retHashMap = getWarehouse();

        // 検索条件の納入先へ自倉庫を固定値として設定
        orderReceiptSerchVORow.setAttribute("LocationCode", retHashMap.get("LocationCode")); // 保管倉庫コード
        orderReceiptSerchVORow.setAttribute("LocationName", retHashMap.get("LocationName")); // 保管倉庫名
        orderReceiptSerchVORow.setAttribute("LocationCodeReadOnly", Boolean.TRUE);           // 保管倉庫(読取専用へ変更)
      }
    }
  } // setLocationCode

  /***************************************************************************
   * (発注受入検索画面)自倉庫のカウントを取得するメソッドです。
   * @return int 自倉庫のカウント
   * @throws OAException OA例外
   ***************************************************************************
   */
  public int getWarehouseCount() throws OAException
  {
    // 自倉庫のカウントを取得 
    int warehouseCount = XxpoUtility.getWarehouseCount(
                           getOADBTransaction());  // トランザクション

    return warehouseCount;
  } // getWarehouseCount

  /***************************************************************************
   * (発注受入検索画面)自倉庫を取得するメソッドです。
   * @return HashMap 自倉庫情報
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap getWarehouse() throws OAException
  {
    // 自倉庫情報取得 
    HashMap retHashMap = XxpoUtility.getWarehouse(
                           getOADBTransaction());  // トランザクション

    return retHashMap;
  } // getWarehouse

  /***************************************************************************
   * (発注受入検索画面)検索ボタン押下時の必須チェックを行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doRequiredCheck() throws OAException
  {

    // 発注受入:検索項目VO取得
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();
    // 1行目を取得
    OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();

    // 納入日(From)を取得
    Object fdDate  = orderReceiptSerchVORow.getAttribute("DeliveryDateFrom");
    // 納入先コードを取得
    Object locationCode  = orderReceiptSerchVORow.getAttribute("LocationCode");

    ArrayList exceptions = new ArrayList(100);

// 2008-11-05 H.Itou Add Start 統合テスト指摘103
    Object headerNumber  = orderReceiptSerchVORow.getAttribute("HeaderNumber"); // 発注番号

    // 発注番号がNULLのときのみ必須。    
    if (XxcmnUtility.isBlankOrNull(headerNumber))
    {
// 2008-11-05 H.Itou Add End
      // 納入日(From)が設定されていない場合
      if (XxcmnUtility.isBlankOrNull(fdDate))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              orderReceiptSerchVO.getName(),
                              orderReceiptSerchVORow.getKey(),
                              "DeliveryDateFrom",
                              fdDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10002));
      }

      // 納入先が設定されていない場合
      if (XxcmnUtility.isBlankOrNull(locationCode))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              orderReceiptSerchVO.getName(),
                              orderReceiptSerchVORow.getKey(),
                              "LocationCode",
                              locationCode,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10002));
      }

      OAException.raiseBundledOAException(exceptions);
// 2008-11-05 H.Itou Add Start 統合テスト指摘103
    }
// 2008-11-05 H.Itou Add End
  } // doRequiredCheck

  /***************************************************************************
   * (発注受入検索画面)検索処理を行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  ) throws OAException
  {

    // 外部ユーザ識別フラグ取得
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();
    orderReceiptSerchVO.first();
    String peopleCode = (String)orderReceiptSerchVO.getCurrentRow().getAttribute("PeopleCode");
    searchParams.put("PeopleCode", peopleCode);

    // 従業員区分が2:外部の場合、自取引IDを設定
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      searchParams.put("location", orderReceiptSerchVO.getCurrentRow().getAttribute("LocationCode"));
    }

    // 発注受入情報VO取得
    XxpoOrderReceiptVOImpl orderReceiptVO = getXxpoOrderReceiptVO1();

    // 検索
    orderReceiptVO.initQuery(searchParams);  // 検索パラメータ用HashMap

    // 1行目を取得
    OARow row = (OARow)orderReceiptVO.first();
  } // doSearch

  /***************************************************************************
   * (発注受入検索画面)ページングの際にチェックボックスをOFFにします。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void checkBoxOff() throws OAException
  {
    // 発注情報VO取得
    OAViewObject vo = getXxpoOrderReceiptVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    
    // 選択チェックボックスをOFFにします。
    if ((rows != null) || (rows.length != 0))
    {
      OARow row = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i番目の行を取得
        row = (OARow)rows[i];
        row.setAttribute("Selection", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * (発注受入検索画面)処理対象行選択チェックを行います。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkSelect() throws OAException
  {
    // 発注情報VO取得
    OAViewObject vo = getXxpoOrderReceiptVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    // *************************************************** //
    // * 処理1:選択チェックボックスが選択チェック        * //
    // *************************************************** //
    if ((rows == null) || (rows.length == 0))
    {

      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXPO,
                  XxpoConstants.XXPO30040,
                  null,
                  OAException.ERROR,
                  null);
    }
  }

  /***************************************************************************
   * (発注受入検索画面)一括受入処理を行います。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doBatchReceipt() throws OAException
  {

    ArrayList exceptions = new ArrayList(100);

    // 発注情報VO取得
    OAViewObject vo = getXxpoOrderReceiptVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      boolean retFlag;

      // *************************************************** //
      // * 処理2:受入返品実績(アドオン)に登録済みチェック  * //
      // * 処理3:OPM在庫会計CLOSEチェック                  * //
      // * 処理4:未来日チェック                            * //
      // *************************************************** //
      retFlag = chkBatchReceipt(exceptions,
                                vo,
                                row);

      // チェックでエラーが発生した場合、後続処理はスキップ
      if (retFlag)
      {
        continue;
      }

      // *************************************************** //
      // * 処理5:仕入実績作成処理(コンカレント)            * //
      // *************************************************** //
      doStockResultMake(exceptions,
                        vo,
                        row);
      
    }

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      doRollBack();
      OAException.raiseBundledOAException(exceptions);

    // 例外が発生していない場合は、コミット処理
    } else 
    {

      doCommit();

      // 更新完了メッセージ
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30050,
        null,
        OAException.INFORMATION,
        null);
    }

  } // doBatchReceipt

  /***************************************************************************
   * (発注受入検索画面)一括受入処理の事前チェックを行います。
   * @param exceptions エラーリスト
   * @param vo 発注明細VO
   * @param row 処理対象発注データ
   * @return boolean エラー発生:true、エラー無し:false
   * @throws OAException OA例外
   ***************************************************************************
   */
  public boolean chkBatchReceipt(
    ArrayList exceptions,
    OAViewObject vo,
    OARow row
  ) throws OAException
  {

    boolean retFlag;
// 2011-06-01 K.Kubo Add Start

    Number headerId        = (Number)row.getAttribute("HeaderId");        // 発注ヘッダID
    String headerNumber    = (String)row.getAttribute("HeaderNumber");    // 発注番号

    // ************************ //
    // * 仕入実績情報チェック * //
    // ************************ //
    String retFlag2 = XxpoUtility.chkStockResult(
                                    getOADBTransaction(),     // トランザクション
                                    headerId                  // 発注ヘッダID
                      );
    // 同一データが存在する場合（エラーが返ってきた場合）
    if (!(XxcmnConstants.RETURN_NOT_EXE.equals(retFlag2)))
    {
      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10294,
                            null));

      // エラーあり
      return true;
    }
// 2011-06-01 K.Kubo Add End

    // *************************************************** //
    // * 処理2:受入返品実績(アドオン)に登録済みチェック  * //
    // *************************************************** //

// 2011-06-01 K.Kubo DEL Start
//    String headerNumber = (String)row.getAttribute("HeaderNumber"); // 発注番号
// 2011-06-01 K.Kubo DEL End

    // 実績作成済みチェック
    String chkFlag = XxpoUtility.chkRcvAndRtnTxnsInput(
                       getOADBTransaction(),
                       headerNumber);

    // チェックでエラーが発生した場合
    if (XxcmnConstants.STRING_Y.equals(chkFlag))
    {

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10203,
                            null));

      // エラーあり
      return true;
    }

    // *************************************************** //
    // * 処理3:OPM在庫会計CLOSEチェック                  * //
    // *************************************************** //
    Date deliveryDate = (Date)row.getAttribute("DeliveryDate");
    retFlag = XxpoUtility.chkStockClose(
                            getOADBTransaction(),
                            deliveryDate);

    // CLOSEの場合
    if (retFlag)
    {
      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10205,
                            null));
                            
      // エラーあり
      return true;
    }

    // ************************************************** //
    // * 処理4:未来日チェック                           * //
    // ************************************************** //
    // システム日付を取得
    Date sysDate = XxpoUtility.getSysdate(getOADBTransaction());

    // 納入予定日が未来日でないか確認
    retFlag = XxcmnUtility.chkCompareDate(1, deliveryDate, sysDate);

    // チェックでエラーが発生した場合
    if (retFlag)
    {
      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10204,
                            null));

      // エラーあり
      return true;
    }
// 2011-06-01 K.Kubo Add Start
    // 事前チェックで問題ない場合、
    // 仕入実績作成処理管理Tblにデータを登録

    // ************************ //
    // * 仕入実績情報登録     * //
    // ************************ //
    String retFlag3 = XxpoUtility.insStockResult(
                                    getOADBTransaction()      // トランザクション
                                   ,headerId                  // 発注ヘッダID
                                   ,headerNumber              // 発注番号
                      );
    // 正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag3))
    {
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_STOCK_RESULT_MANEGEMENT) };
      throw new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN05002,
                            tokens);

    }
// 2011-06-01 K.Kubo Add End
    // エラー無し
    return false;
  } // chkBatchReceipt

  /***************************************************************************
   * (発注受入検索画面)コンカレント：仕入実績作成処理です。
   * @param exceptions エラーリスト
   * @param vo 発注明細VO
   * @param row 処理対象発注明細
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doStockResultMake(
    ArrayList exceptions,
    OAViewObject vo,
    OARow row
  ) throws OAException
  {

    String headerNumber = (String)row.getAttribute("HeaderNumber"); // 発注番号

    // コンカレント：仕入実績作成処理起動
    String retFlag = XxpoUtility.doStockResultMake(
                                   getOADBTransaction(), // トランザクション
                                   headerNumber);        // 発注番号

    // 正常終了の場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
    {
      //トークン生成
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_STOCK_RESULT_MAKE) };
      throw new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN05002,
                            tokens);

    }
  } // doStockResultMake

// 2008-11-05 H.Itou Add Start 統合テスト指摘104
  /***************************************************************************
   * (発注受入検索画面)納入日Fromを納入日TOへコピーするメソッドです。
   ***************************************************************************
   */
  public void copyDeliveryDateFrom()
  {
    // 発注受入検索VO取得
    OAViewObject vo = getXxpoOrderReceiptSerchVO1();
    // 1行目を取得
    OARow row = (OARow)vo.first();

    Date deliveryDateFrom = (Date)row.getAttribute("DeliveryDateFrom"); // 納入日From
    Date deliveryDateTo   = (Date)row.getAttribute("DeliveryDateTo");   // 納入日To

    // 納入日ToがNullの場合、出庫日Fromをコピー
    if (XxcmnUtility.isBlankOrNull(deliveryDateTo))
    {
      row.setAttribute("DeliveryDateTo", deliveryDateFrom);
    }
  } // copyDeliveryDateFrom
// 2008-11-05 H.Itou Add End

  /***************************************************************************
   * (発注受入詳細画面)初期化処理を行うメソッドです。
   * @param params パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void initialize2(
    HashMap params
  ) throws OAException
  {

    // ***************************** //
    // * パラメータの取得          * //
    // ***************************** //
    String startCondition = (String)params.get("StartCondition");
    String headerNumber   = (String)params.get("HeaderNumber");

    // ******************************************* //
    // * 発注受入詳細:発注受入詳細PVO取得        * //
    // ******************************************* //
    OAViewObject orderReceiptDetailsPVO = getXxpoOrderReceiptDetailsPVO1();

    // 1行もない場合、空行作成
    if (!orderReceiptDetailsPVO.isPreparedForExecution())
    {
      // 1行もない場合、空行作成
      orderReceiptDetailsPVO.setMaxFetchSize(0);
      orderReceiptDetailsPVO.executeQuery();
      orderReceiptDetailsPVO.insertRow(orderReceiptDetailsPVO.createRow());
    }

    // 1行目を取得
    OARow orderReceiptDetailsPVORow = (OARow)orderReceiptDetailsPVO.first();
    String chkHeaderNumber = (String)orderReceiptDetailsPVORow.getAttribute("HeaderNumber");

    // キー値をセット
    orderReceiptDetailsPVORow.setAttribute("RowKey", new Number(1));
    // 起動条件をセット
    orderReceiptDetailsPVORow.setAttribute("pStartCondition", startCondition);
    // 発注番号をセット
    orderReceiptDetailsPVORow.setAttribute("pHeaderNumber",   headerNumber);

// 20080528 add yoshimoto Start
    // *************************** //
    // * ユーザー情報取得        * //
    // *************************** //
    getUserData(orderReceiptDetailsPVORow);
// 20080528 add yoshimoto End

    // *********************************************** //
    // * 起動条件が "1"(メニューから起動)の場合      * //
    // *********************************************** //
    if (XxpoConstants.START_CONDITION_1.equals(startCondition))
    {

      // ************************ //
      // * 項目制御             * //
      // ************************ //
      // 適用ボタンをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.TRUE);
      // ヘッダ.摘要をReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
      // 検索ボタンをレンダリング済みへ変更
      orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.TRUE);
      // 消去ボタンをレンダリング済みへ変更
      orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.TRUE);

      // 発注が特定されている場合
      if (!"-1".equals(headerNumber))
      {

        // ************************************** //
        // * 発注受入詳細:発注ヘッダVO 空行取得 * //
        // ************************************** //
        XxpoOrderHeaderVOImpl orderHeaderVO = getXxpoOrderHeaderVO1();
        OARow orderHeaderVORow = null;

        // 検索実施
        orderHeaderVO.initQuery(params);

        // データが取得できない場合、エラーページへ遷移する
        if (orderHeaderVO.getRowCount() == 0)
        {
          orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

          // ************************ //
          // * エラーメッセージ出力 * //
          // ************************ //
          throw new OAException(
                      XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10500,
                      null,
                      OAException.ERROR,
                      null);
        }

        // ***************************************** //
        // * 発注受入詳細:登録ヘッダVO 入力制御    * //
        // ***************************************** //
        orderHeaderVORow = (OARow)orderHeaderVO.first();
        String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");

        // ステータスが"金額確定済"(35)の場合
        if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
        {
          // ヘッダ.摘要のReadOnlyを解除
          orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
        } else 
        {
          // ヘッダ.摘要のReadOnlyを解除
          orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.FALSE);
        }

        // ************************************** //
        // * 発注受入詳細:発注明細VO 空行取得   * //
        // ************************************** //
        XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
        OARow orderDetailsTabVOow = null;

        // 検索実施
        orderDetailsTabVO.initQuery(headerNumber);

        // データが取得できない場合、エラーページへ遷移する
        if (orderDetailsTabVO.getRowCount() == 0)
        {
          orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

          // ************************ //
          // * エラーメッセージ出力 * //
          // ************************ //
          throw new OAException(
                      XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10500,
                      null,
                      OAException.ERROR,
                      null);
        }

        // ************************ //
        // * 項目制御             * //
        // ************************ //
        // 適用ボタンをReadOnlyを解除
        orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.FALSE);
        // 発注NoをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
        // 支給NoをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
        // 検索ボタンをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

      } else 
      {
        if (!XxcmnUtility.isBlankOrNull(chkHeaderNumber))
        {
          // 適用ボタンをReadOnlyを解除
          orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.FALSE);          
        }
      }

    // *********************************************** //
    // * 起動条件が "2"(発注受入検索から起動)の場合  * //
    // *********************************************** //
    } else 
    {

      // ************************************** //
      // * 発注受入詳細:発注ヘッダVO 空行取得 * //
      // ************************************** //
      XxpoOrderHeaderVOImpl orderHeaderVO = getXxpoOrderHeaderVO1();
      OARow orderHeaderVORow = null;

      // 検索実施
      orderHeaderVO.initQuery(params);
   
      // データが取得できない場合、エラーページへ遷移する
      if (orderHeaderVO.getRowCount() == 0)
      {

        // 発注NoをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
        // 支給NoをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
        // 検索ボタンを非レンダリングへ変更
        orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.FALSE);
        // 消去ボタンを非レンダリングへ変更
        orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.FALSE);
        // 摘要ボタンをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.TRUE);
        // ヘッダ.摘要をReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",   Boolean.TRUE);

        // ************************ //
        // * エラーメッセージ出力 * //
        // ************************ //
        throw new OAException(
                    XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN10500,
                    null,
                    OAException.ERROR,
                    null);
      }

      // ***************************************** //
      // * 発注受入詳細:登録ヘッダVO 入力制御    * //
      // ***************************************** //
      orderHeaderVORow = (OARow)orderHeaderVO.first();
      String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");

      // ステータスが"金額確定済"(35)の場合
      if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
      {
        // ヘッダ.摘要のReadOnlyを解除
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
      } else
      {
        // ヘッダ.摘要のReadOnlyを解除
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.FALSE);
      }

      orderReceiptDetailsPVORow.setAttribute("HeaderNumber", (String)orderHeaderVO.first().getAttribute("HeaderNumber"));
      orderReceiptDetailsPVORow.setAttribute("RequestNumber", (String)orderHeaderVO.first().getAttribute("RequestNumber"));

      // ************************************** //
      // * 発注受入詳細:発注明細VO 空行取得   * //
      // ************************************** //
      XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
      OARow orderDetailsTabVOow = null;

      // 検索実施
      orderDetailsTabVO.initQuery(headerNumber);

      // データが取得できない場合、エラーページへ遷移する
      if (orderDetailsTabVO.getRowCount() == 0)
      {

        // 発注NoをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
        // 支給NoをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
        // 検索ボタンを非レンダリングへ変更
        orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.FALSE);
        // 消去ボタンを非レンダリングへ変更
        orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.FALSE);
        // 摘要ボタンをReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.TRUE);
        // ヘッダ.摘要をReadOnlyへ変更
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",   Boolean.TRUE);

        // ************************ //
        // * エラーメッセージ出力 * //
        // ************************ //
        throw new OAException(
                      XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10500,
                      null,
                      OAException.ERROR,
                      null);
      }

      // ************************ //
      // * 項目制御             * //
      // ************************ //
      // 適用ボタンをReadOnlyを解除
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.FALSE);
      // 発注NoをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
      // 支給NoをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
      // 検索ボタンを非レンダリングへ変更
      orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.FALSE);
      // 消去ボタンを非レンダリングへ変更
      orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.FALSE);

    }

    // ************************************************* //
    // * 発注受入詳細:合計算出VO 初期表示行取得        * //
    // ************************************************* //
    XxpoOrderDetailTotalVOImpl orderDetailTotalVO = getXxpoOrderDetailTotalVO1();
 
    // 検索実施
    // 1行もない場合
    if (!"-1".equals(headerNumber)) {
      orderDetailTotalVO.initQuery(headerNumber);
      orderDetailTotalVO.first();
    }

    // ***************************************** //
    // * 発注受入詳細:発注明細VO 入力制御      * //
    // ***************************************** //
    // 発注が特定されている場合
    if (!"-1".equals(headerNumber))
    {
      XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
      if (orderDetailsTabVO.getRowCount() > 0)
      {

        // 発注明細の入力制御を実施
        readOnlyChangedDetailsTab();

      }
    }
  } // initialize2

  /***************************************************************************
   * (発注受入詳細画面)入力制御(発注明細)を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void readOnlyChangedDetailsTab() throws OAException
  {

    // 発注受入詳細:発注明細VO取得
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    // 現在行が取得できる間、処理を繰り返す
    while (orderDetailsTabVO.getCurrentRow() != null)
    {

      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();

      // 明細.金額確定フラグを取得
      String moneyDecisionFlag = (String)orderDetailsTabVORow.getAttribute("MoneyDecisionFlag");
// 20080708 Mod D.Nihei Start
//      // 明細.原価管理区分を取得
//      String costManageCode = (String)orderDetailsTabVORow.getAttribute("CostManageCode");
      // 明細.品目区分を取得
      String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
// 20080708 Mod D.Nihei End

      // ***************************************** //
      // * 金額確定フラグによる製造日項目制御    * //
      // ***************************************** //
      // 明細金額確定フラグが"金額確定済"(Y)の場合
      if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
      {

        // 発注明細の製造日を読取専用に変更
        orderDetailsTabVORow.setAttribute("ProductionDateReadOnly",  Boolean.TRUE);
        // 発注明細の入数を読取専用に変更
        orderDetailsTabVORow.setAttribute("ItemAmountReadOnly",      Boolean.TRUE);
        // 発注明細の全受を読取専用に変更
        orderDetailsTabVORow.setAttribute("AllReceiptReadOnly",      Boolean.TRUE);
        // 発注明細の摘要を読取専用に変更
        orderDetailsTabVORow.setAttribute("OrderDetailDescReadOnly", Boolean.TRUE);

// 20080708 Mod D.Nihei Start
//      // 品目の原価管理区分が実勢(0)以外の場合
//      } else if (!XxpoConstants.COST_MANAGE_CODE_R.equals(costManageCode))
      // 品目の品目区分が「5：製品」の場合
      } else if (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
// 20080708 Mod D.Nihei End
      {

        // 発注明細の製造日を読取専用に変更
        orderDetailsTabVORow.setAttribute("ProductionDateReadOnly", Boolean.TRUE);

      }

      // ************************************ //
      // * 換算有無チェック                 * //
      // ************************************ //
      boolean conversionFlag = false;
      String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
// 20080708 Del D.Nihei Start
//      String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
// 20080708 Del D.Nihei End
      String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

      // 換算有無チェックを実施
      conversionFlag = chkConversion(
                         prodClassCode,  // 商品区分
                         itemClassCode,  // 品目区分
                         convUnit);      // 入出庫換算単位

      // *********************************** //
      // *  入数項目制御                   * //
      // *********************************** //
      if (conversionFlag)
      {
        // 発注明細の入数を読取専用に変更
        orderDetailsTabVORow.setAttribute("ItemAmountReadOnly", Boolean.TRUE);
      }

      orderDetailsTabVO.next();
    }
    // 20080627 Add Start
    orderDetailsTabVO.first();
    // 20080627 Add End
  } // readOnlyChangedReceiptDetails2

  /***************************************************************************
   * (発注受入詳細画面)検索ボタン押下時の必須チェックを行うメソッドです。
   * @param params チェック項目
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doRequiredCheck2(
    HashMap params
  ) throws OAException
  {

    // 発注受入詳細PVOを取得
    OAViewObject vo = getXxpoOrderReceiptDetailsPVO1();
    OARow row = (OARow)vo.first();

    // 発注Noを取得
    Object headerNumber  = params.get("HeaderNumber");
    // 支給Noを取得
    Object requestNumber = params.get("RequestNumber");

    ArrayList exceptions = new ArrayList(100);

    // 発注Noと支給Noの両項目が設定されていない場合
    if ((XxcmnUtility.isBlankOrNull(headerNumber))
      && (XxcmnUtility.isBlankOrNull(requestNumber)))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10035));

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "RequestNumber",
                            requestNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10035));

    }

    OAException.raiseBundledOAException(exceptions);

  } // doRequiredCheck2

  /***************************************************************************
   * (発注受入詳細画面)画面パラメータを取得するメソッドです。
   * @return HashMap 画面パラメータ
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap getDetailPageParams() throws OAException
  {
    // ************************************** //
    // * 発注受入詳細:発注受入詳細PVO取得   * //
    // ************************************** //
    OAViewObject orderReceiptDetailsPVO = getXxpoOrderReceiptDetailsPVO1();
    OARow orderReceiptDetailsPVORow = (OARow)orderReceiptDetailsPVO.first();

    HashMap retHashMap = new HashMap();

    retHashMap.put("pStartCondition", orderReceiptDetailsPVORow.getAttribute("pStartCondition")); // 起動条件
    retHashMap.put("pHeaderNumber", orderReceiptDetailsPVORow.getAttribute("pHeaderNumber"));     // 発注番号
    retHashMap.put("HeaderNumber", orderReceiptDetailsPVORow.getAttribute("HeaderNumber"));       // 発注番号

    return retHashMap;

  } // getDetailPageParams

  /***************************************************************************
   * (発注受入詳細画面)検索処理を行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearch2(
    HashMap searchParams
  ) throws OAException
  {
    // 検索条件取得
    String headerNumber  = (String)searchParams.get("HeaderNumber");  // 発注No
    String requestNumber = (String)searchParams.get("RequestNumber"); // 支給No

    // ******************************************* //
    // * 発注受入詳細:発注受入詳細PVO 空行取得   * //
    // ******************************************* //
    OAViewObject orderReceiptDetailsPVO = getXxpoOrderReceiptDetailsPVO1();
    OARow orderReceiptDetailsPVORow = (OARow)orderReceiptDetailsPVO.first();

    // **************************************** //
    // * 発注受入詳細:発注ヘッダVO 空行取得   * //
    // **************************************** //
    XxpoOrderHeaderVOImpl orderHeaderVO = getXxpoOrderHeaderVO1();

    // 検索実施
    orderHeaderVO.initQuery(searchParams);

    // データが取得できない場合、エラーページへ遷移する
    if (orderHeaderVO.getRowCount() == 0)
    {
      // ************************ //
      // * 項目制御             * //
      // ************************ //
      // 適用ボタンをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);
      // 検索ボタンをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      throw new OAException(
                    XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN10500,
                    null,
                    OAException.ERROR,
                    null);
    }

    // ***************************************** //
    // * 発注受入詳細:登録ヘッダVO 入力制御    * //
    // ***************************************** //
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();
    String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");

    // ステータスが"金額確定済"(35)の場合
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      // ヘッダ.摘要のReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
    } else 
    {
      // ヘッダ.摘要のReadOnlyを解除
      orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.FALSE);
    }

    headerNumber  = (String)orderHeaderVO.first().getAttribute("HeaderNumber");
    requestNumber = (String)orderHeaderVO.first().getAttribute("RequestNumber");
    orderReceiptDetailsPVORow.setAttribute("HeaderNumber",  headerNumber);
    orderReceiptDetailsPVORow.setAttribute("RequestNumber", requestNumber);


    // ************************************** //
    // * 発注受入詳細:発注明細VO 空行取得   * //
    // ************************************** //
    XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVOow = null;

    // 検索実施
    orderDetailsTabVO.initQuery(headerNumber);

    // データが取得できない場合、エラーページへ遷移する
    if (orderDetailsTabVO.getRowCount() == 0)
    {
      // ************************ //
      // * 項目制御             * //
      // ************************ //
      // 適用ボタンをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);
      // 検索ボタンをReadOnlyへ変更
      orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500,
                  null,
                  OAException.ERROR,
                  null);
    }

    // ************************************************* //
    // * 発注受入詳細:合計算出VO 初期表示行取得        * //
    // ************************************************* //
    XxpoOrderDetailTotalVOImpl orderDetailTotalVO = getXxpoOrderDetailTotalVO1();

    // 検索実施
    orderDetailTotalVO.initQuery(headerNumber);
    orderDetailTotalVO.first();
    
    // ************************ //
    // * 項目制御             * //
    // ************************ //
    // 適用ボタンのReadOnlyを解除
    orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.FALSE);
    // 発注NoをReadOnlyへ変更
    orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
    // 支給NoをReadOnlyへ変更
    orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
    // 検索ボタンをReadOnlyへ変更
    orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

    // ***************************************** //
    // * 発注受入詳細:発注明細VO 入力制御      * //
    // ***************************************** //
    if (orderDetailsTabVO.getRowCount() > 0)
    {
      // 発注明細の入力制御を実施
      readOnlyChangedDetailsTab();
    }
    
  } // doSearch2

  /***************************************************************************
   * (発注受入詳細画面)製造日変更時処理です。
   * @param params パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void productedDateChanged(
    HashMap params
  ) throws OAException
  {
    // 賞味期限取得
    getUseByDate(params);
  } // productedDateChanged

  /***************************************************************************
   * (発注受入詳細画面)賞味期限を取得するメソッドです。
   * @param params パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getUseByDate(
    HashMap params
  ) throws OAException
  {
    String searchLineNum = 
      (String)params.get(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

    // 登録明細VO取得
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    // 1行めを取得
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    while(orderDetailsTabVO.getCurrentRow() != null)
    {
      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();
      
      if (searchLineNum.equals(orderDetailsTabVORow.getAttribute("LineNum").toString()))
      {
        break;
      }
      
      orderDetailsTabVO.next();
      
    }

    // データ取得
    Date productedDate   = (Date)orderDetailsTabVORow.getAttribute("ProductionDate");  // 製造日
    Number itemId        = (Number)orderDetailsTabVORow.getAttribute("OpmItemId");     // OPM品目ID
    Number expirationDay = (Number)orderDetailsTabVORow.getAttribute("ExpirationDay"); // 賞味期間

    // 製造日が入力されていない(削除された)場合は算出を行わない
    if (productedDate != null)
    {
      // 賞味期間に値がある場合、賞味期限取得
      if (!XxcmnUtility.isBlankOrNull(expirationDay))
      {

        Date useByDate = XxpoUtility.getUseByDate(
                           getOADBTransaction(),      // トランザクション
                           itemId,                    // OPM品目ID
                           productedDate,             // 製造日
                           expirationDay.toString()); // 賞味期間

        // 賞味期限を外注出来高情報:登録VOにセット
        orderDetailsTabVORow.setAttribute("UseByDate", useByDate);
    
      // 賞味期間に値がない場合、NULL
      } else
      {
        // 賞味期限を仕入先出荷実績情報:登録明細VOにセット
        orderDetailsTabVORow.setAttribute("UseByDate", productedDate);
      }
    }
  } // getUseByDate

  /***************************************************************************
   * (発注受入詳細画面)登録・更新前チェック処理を行います。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void dataCheck() throws OAException
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    
    // ********************************** //
    // * 処理1:入力項目チェックを実施   * //
    // *   1-1:入数入力値チェック       * //
    // ********************************** //
    messageTextInputCheck2(exceptions);

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

  } // dataCheck

  /***************************************************************************
   * (発注受入詳細画面)項目入力値チェックを行うメソッドです。
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextInputCheck2(
    ArrayList exceptions
  ) throws OAException
  {
    // 発注受入詳細:発注明細VO取得
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    while (orderDetailsTabVO.getCurrentRow() != null)
    {

      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();

      // ************************************ //
      // * 処理1-1:入数入力値チェック   * //
      // ************************************ //
      // 行単位での入数チェックを実施
      messageTextQuantityRowCheck2(orderDetailsTabVO,
                                   orderDetailsTabVORow,
                                   exceptions);

      orderDetailsTabVO.next();

    }

  } // messageTextInputCheck2

  /***************************************************************************
   * (発注受入詳細画面)行単位で入数チェックを行うメソッドです。
   * @param checkVo チェック対象VO
   * @param checkRow チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextQuantityRowCheck2(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException
  {

    // 入数を取得
    String itemAmount = (String)checkRow.getAttribute("ItemAmount");

    // ************************************ //
    // * 処理1-1:入数入力値チェック       * //
    // ************************************ //
    // 入数が0未満の場合はエラー
    if (!XxcmnUtility.isBlankOrNull(itemAmount))
    {
      // 数値でない場合はエラー
      if (!XxcmnUtility.chkNumeric(XxcmnUtility.commaRemoval(itemAmount), 5, 3))
      {

        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "ItemAmount",
                              itemAmount,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10001));

      // 0以下はエラー
      } else if(!XxcmnUtility.chkCompareNumeric(2, XxcmnUtility.commaRemoval(itemAmount), "0"))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY,
                                     XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);

        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "ItemAmount",
                              itemAmount,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10068,
                              tokens));

      }
    }
  } // messageTextQuantityRowCheck2

  /***************************************************************************
   * (発注受入詳細画面)登録更新処理を行うメソッドです。
   * @return String 成功(更新有):xcmnConstants.STRING_TRUE、
   *                 成功(更新無):xcmnConstants.RETURN_SUCCESS、
   *                 失敗:xcmnConstants.RETURN_NOT_EXE
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String apply() throws OAException
  {

    // 登録更新処理結果
    String retCode = XxcmnConstants.RETURN_NOT_EXE;
    // 更新確認フラグ
    boolean updFlag = false;

    // ******************************** //
    // * 発注ヘッダ更新処理           * //
    // ******************************** //
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // 発注ヘッダロック取得処理
    getHeaderRowLock(
      (Number)orderHeaderVORow.getAttribute("HeaderId"));

    // 発注ヘッダ排他制御
    chkHdrExclusiveControl(
      (Number)orderHeaderVORow.getAttribute("HeaderId"),
      (String)orderHeaderVORow.getAttribute("LastUpdateDate"));

    
    if (!XxcmnUtility.isEquals(orderHeaderVORow.getAttribute("Description"),
           orderHeaderVORow.getAttribute("BaseDescription")))
    {

      // 更新フラグをtrueへ
      updFlag = true;

      // 発注ヘッダー更新：実行
      retCode = updHeaderDesc(orderHeaderVORow);

      // 更新処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {

        return XxcmnConstants.RETURN_NOT_EXE;
      }

    }

    // ******************************** //
    // * 発注明細・ロットMST更新処理  * //
    // ******************************** //
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    while (orderDetailsTabVO.getCurrentRow() != null)
    {

      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();

      // 発注明細ロック取得処理
      getDetailsRowLock(
        (Number)orderDetailsTabVORow.getAttribute("LineId"));

      // 発注明細排他制御
      chkDetailsExclusiveControl(
        (Number)orderDetailsTabVORow.getAttribute("LineId"),
        (String)orderDetailsTabVORow.getAttribute("LastUpdateDate"));

      // ******************************** //
      // * 発注明細更新処理             * //
      // ******************************** //
      String baseItemAmount = (String)orderDetailsTabVORow.getAttribute("BaseItemAmount");
      // (DB)入数が取得されている場合は、カンマを除去
      if (!XxcmnUtility.isBlankOrNull(baseItemAmount))
      {
        baseItemAmount = XxcmnUtility.commaRemoval(baseItemAmount);
      }
      
// 20080523 add yoshimoto Start
      String itemAmount = XxcmnUtility.commaRemoval(
                            (String)orderDetailsTabVORow.getAttribute("ItemAmount"));
// 20080523 add yoshimoto End      
      if ((!XxcmnUtility.chkCompareNumeric(3, itemAmount, baseItemAmount))
        || (!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("Description"),
               orderDetailsTabVORow.getAttribute("BaseDescription"))))
      {

        // 更新フラグをtrueへ
        updFlag = true;

        // 発注明細更新：実行
        retCode = updItemAmountAndDesc(orderDetailsTabVORow);

        // 更新処理が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {

          return XxcmnConstants.RETURN_NOT_EXE;
        } 

      }

      // ******************************** //
      // * ロットMST更新処理            * //
      // ******************************** //
      // 品目がロット対象である場合
      Number lotCtl = (Number)orderDetailsTabVORow.getAttribute("LotCtl");
      if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
      {

        // ロットMSTロック取得処理
        getOpmLotMstRowLock(
          (String)orderDetailsTabVORow.getAttribute("LotNo"),      // ロットNo
          (Number)orderDetailsTabVORow.getAttribute("OpmItemId")); // OPM品目ID

        // ロットMST排他制御
        chkOpmLotMstExclusiveControl(
          (String)orderDetailsTabVORow.getAttribute("LotNo"),              // ロットNo
          (Number)orderDetailsTabVORow.getAttribute("OpmItemId"),          // OPM品目ID
          (String)orderDetailsTabVORow.getAttribute("LotLastUpdateDate")); // 最終更新日

        if ((!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("ProductionDate"),
                orderDetailsTabVORow.getAttribute("BaseProductionDate")))
          || (!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("UseByDate"),
                 orderDetailsTabVORow.getAttribute("BaseUseByDate")))
// 20080523 add yoshimoto Start                 
          || (!XxcmnUtility.chkCompareNumeric(3, itemAmount, baseItemAmount))
          || (!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("Description"),
                 orderDetailsTabVORow.getAttribute("BaseDescription"))))
// 20080523 add yoshimoto End
        {

          // 更新フラグをtrueへ
          updFlag = true;

          HashMap setParams = new HashMap();

          // OPM品目ID
          setParams.put("ItemId", orderDetailsTabVORow.getAttribute("OpmItemId"));
          // ロットNo
          setParams.put("LotNo",  orderDetailsTabVORow.getAttribute("LotNo"));
          // 製造日
          setParams.put("ProductionDate", orderDetailsTabVORow.getAttribute("ProductionDate"));
          // 賞味期限
          setParams.put("UseByDate", orderDetailsTabVORow.getAttribute("UseByDate"));

// 20080523 add yoshimoto Start
          // 入数
          setParams.put("ItemAmount", itemAmount);
          // 明細摘要
          setParams.put("Description", orderDetailsTabVORow.getAttribute("Description"));
// 20080523 add yoshimoto End

          // ロットMST更新：実行
          retCode = XxpoUtility.updateIcLotsMstTxns2(
                      getOADBTransaction(),
                      setParams);

          // 更新処理が正常終了でない場合
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
          {
            return XxcmnConstants.RETURN_NOT_EXE;
          } 

        }
      }

      orderDetailsTabVO.next();
    }

    // 更新が行われている場合は、STRING_TRUEを返す
    if (updFlag)
    {
      return XxcmnConstants.STRING_TRUE;
      
    }
    
    // 更新が行われていないが、正常終了の場合はRETURN_SUCCESSを返す
    return XxcmnConstants.RETURN_SUCCESS;
  } // apply
 
  /***************************************************************************
   * (発注受入詳細画面)全受更新前チェックを行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public ArrayList chkAllReceipt() throws OAException
  {
    ArrayList exceptions = new ArrayList();
    ArrayList lineIdList = new ArrayList();
    
    // 全受ON有無フラグ
    boolean allReceiptFlag = false;

    // ******************************** //
    // * 発注明細・ロットMST更新処理  * //
    // ******************************** //
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    Row[]rows = orderDetailsTabVO.getFilteredRows("AllReceipt", XxcmnConstants.STRING_Y);

    // フィルタ後、レコードが1行以上存在する場合
    if (rows.length > 0)
    {
      // 全受ON有無フラグをtrueへ
      allReceiptFlag = true;
    }
// 2011-06-01 K.Kubo Add Start
    // 仕入実績作成処理管理Tblにデータが存在する場合、
    // 処理を中断する。

    // 発注受入詳細:発注ヘッダVO取得
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // 発注ヘッダIDを取得
    Number headerId = (Number)orderHeaderVORow.getAttribute("HeaderId");

    // ************************ //
    // * 仕入実績情報チェック * //
    // ************************ //
    String retFlag2 = XxpoUtility.chkStockResult(
                                    getOADBTransaction(),     // トランザクション
                                    headerId                  // 発注ヘッダID
                      );
    // 同一データが存在する場合（エラーが返ってきた場合）
    if (!XxcmnConstants.RETURN_NOT_EXE.equals(retFlag2))
    {
      // エラーメッセージを追加
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            orderHeaderVO.getName(),
                            orderHeaderVORow.getKey(),
                            "HeaderId",
                            headerId,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10294));
    }

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

// 2011-06-01 K.Kubo Add End

    for (int i = 0; i < rows.length; i++)
    {

      orderDetailsTabVORow = (OARow)rows[i];

      // *************************************************** //
      // * 処理2:受入返品実績(アドオン)に登録済みチェック  * //
      // *************************************************** //
      Number lineNumber = (Number)orderDetailsTabVORow.getAttribute("LineNum"); // 発注明細番号

      // 発注明細の数量確定Flagが'Y'の場合は、実績作成済み
      String decisionAmountFlag = (String)orderDetailsTabVORow.getAttribute("DecisionAmountFlag");

      // チェックでエラーが発生した場合
      if (XxcmnConstants.STRING_Y.equals(decisionAmountFlag))
      {

        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              orderDetailsTabVO.getName(),
                              orderDetailsTabVORow.getKey(),
                              "LineNum",
                              lineNumber,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10203,
                              null));

      }

    }


    // 全受ON有無フラグがTrueの場合
    if (allReceiptFlag)
    {
// 2011-06-01 K.Kubo Mod Start
//      // 発注受入詳細:発注ヘッダVO取得
//      OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
//      OARow orderHeaderVORow = (OARow)orderHeaderVO.first();
// 2011-06-01 K.Kubo Mod End
      
      // 納入日(納入予定日)を取得
      Date deliveryDate = (Date)orderHeaderVORow.getAttribute("DeliveryDate");
      
      // ************************************ //
      // * 処理3-1:納入日クローズチェック   * //
      // ************************************ //
      // 納入日が納入日クローズの場合はエラー
      if (XxpoUtility.chkStockClose(
        getOADBTransaction(),
        deliveryDate))
      {
        // エラーメッセージを追加
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              orderHeaderVO.getName(),
                              orderHeaderVORow.getKey(),
                              "DeliveryDate",
                              deliveryDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10205));
      }
  
      // ************************************************** //
      // * 処理3-1:未来日チェック                         * //
      // ************************************************** //
      // システム日付を取得
      Date sysDate = XxpoUtility.getSysdate(getOADBTransaction());
  
      // 納入予定日が未来日の場合
      if (XxcmnUtility.chkCompareDate(1, deliveryDate, sysDate))
      {
        // ************************ //
        // * エラーメッセージ出力 * //
        // ************************ //
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              orderHeaderVO.getName(),
                              orderHeaderVORow.getKey(),
                              "DeliveryDate",
                              deliveryDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10204,
                              null));
      }
  
      // 例外があった場合、例外メッセージを出力し、処理終了
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
  
      // *************************************** //
      // * 処理3-2:受入日後倒しの確認          * //
      // *************************************** //
      for (int i = 0; i < rows.length; i++)
      {
  
        orderDetailsTabVORow = (OARow)rows[i];
  
        // 納入日過去日付チェックフラグ
        boolean dateOfPastFlag = false;
  
        // ************************************ //
        // * 換算有無チェック                 * //
        // ************************************ //
        boolean conversionFlag = false;
        String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
        String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
        String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");
  
        // 換算有無チェックを実施
        conversionFlag = chkConversion(
                           prodClassCode,  // 商品区分
                           itemClassCode,  // 品目区分
                           convUnit);      // 入出庫換算単位
  
        // ************************************ //
        // * 受入作成済みチェック             * //
        // ************************************ //
        // 数量確定フラグを取得
        String decisionAmountFlag = (String)orderDetailsTabVORow.getAttribute("DecisionAmountFlag");
        
        // 発注明細の数量確定フラグが'Y'の場合
        if (!XxcmnConstants.STRING_Y.equals(decisionAmountFlag))
        {
  
          // 納入日予定日が過去日付の場合(SYSDATE > 納入予定日)
          if (XxcmnUtility.chkCompareDate(1, sysDate, deliveryDate))
          {
  
            String locationCode = (String)orderHeaderVORow.getAttribute("LocationCode");
            Number opmItemId    = (Number)orderDetailsTabVORow.getAttribute("OpmItemId");
            Number lotId        = (Number)orderDetailsTabVORow.getAttribute("LotId");
  
            // ************************************* //
            // * 引当可能数量を取得                * //
            // *   paramsRet(0) : 有効日引当可能数 * //
            // *   paramsRet(1) : 総引当可能数     * //
            // ************************************* //
// 20080630 yoshimoto mod Start
            HashMap paramsRet = XxpoUtility.getReservedQuantity(
                                              getOADBTransaction(),
                                              opmItemId,            // OPM品目ID
                                              locationCode,         // 納入先コード
                                              lotId,                // ロットID
                                              "");
// 20080630 yoshimoto mod End
  
            // 発注数量を取得
            String orderAmount = (String)orderDetailsTabVORow.getAttribute("OrderAmount");
            // カンマ及び小数点を除去
            String sOrderAmount = XxcmnUtility.commaRemoval(orderAmount);
  
            // 在庫入数
            String itemAmount = (String)orderDetailsTabVORow.getAttribute("ItemAmount");
            // カンマ及び小数点を除去
            String sItemAmount = XxcmnUtility.commaRemoval(itemAmount);
  
            // 換算が必要な場合は、在庫入数で乗算
            if (conversionFlag)
            {
              double dOrderAmount = Double.parseDouble(sOrderAmount) * Double.parseDouble(sItemAmount);
              sOrderAmount = Double.toString(dOrderAmount);
            }
  
            // ************************************ //
            // * 受入後倒しチェック               * //
            // ************************************ //
            // 有効日ベース引当可能数
            Object inTimeQty = paramsRet.get("InTimeQty");
            // 総引当可能数
            Object totalQty  = paramsRet.get("TotalQty");
  
            // 『発注数量 > 有効日ベース引当可能数』または、『発注数量 > 総引当可能数』
            if ((XxcmnUtility.chkCompareNumeric(1, sOrderAmount, inTimeQty.toString()))
              || (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, totalQty.toString())))
            {
  
              // 受入日後倒しの確認(警告)
              // lineIdを設定
              lineIdList.add(orderDetailsTabVORow.getAttribute("LineId"));
  
            }
          }
        }
      }

    }

    return lineIdList;
  } // chkAllReceipt

  /***************************************************************************
   * (発注受入詳細画面)発注ヘッダの摘要を更新するメソッドです。
   * @param row 更新対象行
   * @return String 正常：TRUE、エラー：FALSE
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String updHeaderDesc(OARow row) throws OAException
  {

    HashMap params = new HashMap();

    Number HeaderId = (Number)row.getAttribute("HeaderId");
    // ヘッダーID
    params.put("HeaderId",    HeaderId.toString());
    // 適用
    params.put("Description", row.getAttribute("Description"));

    // 発注ヘッダー更新：実行
    String retCode = XxpoUtility.updatePoHeadersAllTxns(
                       getOADBTransaction(), // トランザクション
                       params);              // パラメータ

    // 更新処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    }

    return XxcmnConstants.STRING_TRUE;

  } // updHeaderDesc

  /***************************************************************************
   * (発注受入詳細画面)発注明細の在庫入数/摘要を更新するメソッドです。
   * @param row 更新対象行
   * @return String 正常：TRUE
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String updItemAmountAndDesc(
    OARow row
  ) throws OAException
  {

    HashMap params = new HashMap();

    // 在庫入数
    String itemAmount = (String)row.getAttribute("ItemAmount");
    // カンマ及び小数点を除去
    String sItemAmount = XxcmnUtility.commaRemoval(itemAmount);
    

    // 明細ID
    params.put("LineId",      row.getAttribute("LineId"));
    // 在庫入数
    params.put("ItemAmount",  sItemAmount);
    // 明細適用
    params.put("Description", row.getAttribute("Description"));

    // 発注明細更新：実行
    XxpoUtility.updateItemAmount(
                  getOADBTransaction(), // トランザクション
                  params);              // パラメータ

    return XxcmnConstants.STRING_TRUE;

  } // updItemAmountAndDesc

  /***************************************************************************
   * (発注受入詳細画面)トークン用の情報を取得するメソッドです。
   * @param lineId 発注明細ID
   * @return HashMap トークン
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap getToken(
    Number lineId
  ) throws OAException
  {
    // トークンを格納
    HashMap tokens = new HashMap();

    // 発注ヘッダVOを取得
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // 発注明細VOを取得
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow     = (OARow)orderDetailsTabVO.getFirstFilteredRow("LineId", lineId);

    // 納入先名
    tokens.put(XxcmnConstants.TOKEN_LOCATION, (String)orderHeaderVORow.getAttribute("LocationName"));
    // 品目名
    tokens.put(XxcmnConstants.TOKEN_ITEM,     (String)orderDetailsTabVORow.getAttribute("OpmItemName"));
    // ロットNo
    tokens.put(XxcmnConstants.TOKEN_LOT,      (String)orderDetailsTabVORow.getAttribute("LotNo"));

    return tokens;
  } // getToken

  /***************************************************************************
   * (発注受入詳細画面)全受処理を行うメソッドです。
   * @return HashMap 成功(更新有):xcmnConstants.STRING_TRUE、
   *                 成功(更新無):xcmnConstants.RETURN_SUCCESS、
   *                 失敗:xcmnConstants.RETURN_NOT_EXE
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap doAllReceipt() throws OAException
  {

    // 登録処理結果
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;

    // 発注ヘッダVOを取得
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // 発注明細VOを取得
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    // 合計受入数量
    double receiptAmountTotal = 0.000;

    // 取引ID
    Number txnsId = null;

    // グループID
    Number groupId = null;
    String retGroupId = null;


    Row[] rows = orderDetailsTabVO.getFilteredRows("AllReceipt", XxcmnConstants.STRING_Y);

    for (int i = 0; i < rows.length; i++)
    {

      orderDetailsTabVORow = (OARow)rows[i];

      // ********************************************** //
      // * 処理3-4:受入返品実績(アドオン)登録処理     * //
      // ********************************************** //
      retHashMap = (HashMap)insRcvAndRtnTxns(
                              orderHeaderVORow, 
                              orderDetailsTabVORow);

      retCode = (String)retHashMap.get("RetFlag");

      // 登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }

      // 受入返品実績(アドオン).取引IDを取得
      txnsId = (Number)retHashMap.get("TxnsId");

      // 発注数量を取得
      String orderAmount = (String)orderDetailsTabVORow.getAttribute("OrderAmount");

      // カンマを除去
      orderAmount = XxcmnUtility.commaRemoval(orderAmount);

      // 発注数量が0より多い場合
      if (XxcmnUtility.chkCompareNumeric(1, orderAmount, "0"))
      {
        // ************************************************ //
        // * 処理3-3:受入オープンインタフェース登録処理   * //
        // ************************************************ //
        retHashMap = insOpenIf(
                       orderHeaderVORow,
                       orderDetailsTabVORow,
                       txnsId,
                       groupId);

        retCode = (String)retHashMap.get("RetFlag");
        retGroupId = retCode.toString();
        
        // 登録処理が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
          return retHashMap;
        }

        // グループIDを退避
        groupId = (Number)retHashMap.get("GroupId");
        retGroupId = groupId.toString();
      }

      // *********************************** //
      // * 処理3-5:発注明細更新処理        * //
      // *********************************** //
      // 発注残数
      String orderRemainder = XxcmnUtility.commaRemoval(             // カンマを除去
                                (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
      double dorderRemainder = Double.parseDouble(orderRemainder);   // double型へ変換
    
      // 更新処理
      XxpoUtility.updateReceiptAmount(
        getOADBTransaction(),
        (Number)orderDetailsTabVORow.getAttribute("LineId"),
        dorderRemainder);

      // *********************************** //
      // * 処理3-6:ロット更新処理          * //
      // *********************************** //
      // 品目がロット対象である場合
      Number lotCtl = (Number)orderDetailsTabVORow.getAttribute("LotCtl");
      if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
      {

        // 更新処理
        updIcLotsMstTxns(
          orderHeaderVORow,
          orderDetailsTabVORow);

      }

      // ************************************ //
      // * 処理3-9:在庫数量API起動処理      * //
      // ************************************ //
      // 発注区分を取得
      String orderDivision = (String)orderHeaderVORow.getAttribute("OrderDivision");

      // 発注区分が相手先在庫である場合
      if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
      {
        insIcTranCmp(txnsId,
                     orderHeaderVORow,
                     orderDetailsTabVORow); // 取引ID

      }
// 20080523 del yoshimoto Start
    //}
// 20080523 del yoshimoto End

      // ********************************************** //
      // * 処理3-7,8:発注ステータス変更処理           * //
      // ********************************************** //
      chgStatus();
      
// 20080523 add yoshimoto Start
    }
// 20080523 add yoshimoto End

    // ********************************************** //
    // * 処理4:受入取引処理を起動                   * //
    // ********************************************** //
    if (!XxcmnUtility.isBlankOrNull(groupId))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      retHashMap = XxpoUtility.doRVCTP(
                      getOADBTransaction(),
                      groupId.toString());

      return retHashMap;
    }

    // 全ての処理が正常に終了している場合
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
    return retHashMap;
    
  } // doAllReceipt

  /***************************************************************************
   * (発注受入詳細画面)受入返品実績(アドオン)登録処理を行うメソッドです。
   * @param orderHeaderVORow 発注ヘッダ
   * @param orderDetailsTabVORow 発注明細
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insRcvAndRtnTxns(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsTabVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 実績区分
    setParams.put("TxnsType",               "1");
    // 受入返品番号
    setParams.put("RcvRtnNumber",           orderHeaderVORow.getAttribute("HeaderNumber"));
    // 元文書番号
    setParams.put("SourceDocumentNumber",   orderHeaderVORow.getAttribute("HeaderNumber"));
    // 取引先ID
    setParams.put("VendorId",               orderHeaderVORow.getAttribute("VendorId"));
    // 取引先コード
    setParams.put("VendorCode",             orderHeaderVORow.getAttribute("VendorCode"));
    // 入出庫先コード
    setParams.put("LocationCode",           orderHeaderVORow.getAttribute("LocationCode"));
    // 元文書明細番号
    setParams.put("SourceDocumentLineNum",  orderDetailsTabVORow.getAttribute("LineNum"));
    // 受入返品明細番号
    setParams.put("RcvRtnLineNumber",       new Number(1));
    // 品目ID
    setParams.put("ItemId",                 orderDetailsTabVORow.getAttribute("OpmItemId"));
    // 品目コード
    setParams.put("ItemCode",               orderDetailsTabVORow.getAttribute("OpmItemNo"));
    // ロットID
    setParams.put("LotId",                  orderDetailsTabVORow.getAttribute("LotId"));
    // ロットNo
    setParams.put("LotNumber",              orderDetailsTabVORow.getAttribute("LotNo"));
    // 取引日
    setParams.put("TxnsDate",               orderHeaderVORow.getAttribute("DeliveryDate"));

    // 受入返品数量(発注残数)
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // カンマを除去
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double型へ変換

    setParams.put("RcvRtnQuantity",  new Double(dRcvRtnQuantity).toString());
    // 受入返品単位
    setParams.put("RcvRtnUom",       orderDetailsTabVORow.getAttribute("UnitName"));
    // 単位コード
    setParams.put("Uom",             orderDetailsTabVORow.getAttribute("UnitMeasLookupCode"));
    // 明細摘要
    setParams.put("LineDescription", "");
    // 直送区分
    setParams.put("DropshipCode",    orderDetailsTabVORow.getAttribute("DropshipCode"));
    // 単価
    setParams.put("UnitPrice",       orderDetailsTabVORow.getAttribute("UnitPrice"));
// 20080520 add yoshimoto Start
    // 発注部署コード
    setParams.put("DepartmentCode",  orderHeaderVORow.getAttribute("DepartmentCode"));
// 20080520 add yoshimoto End

    // 換算が必要な場合
    if (conversionFlag)
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 数量
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;
      setParams.put("Quantity",         new Double(dRcvRtnQuantity).toString());
      // 換算入数：換算入数を発注明細.入数とする
      setParams.put("ConversionFactor", sItemAmount);


    // 換算が不要な場合
    } else
    {

      // 数量
      setParams.put("Quantity",         new Double(dRcvRtnQuantity).toString());
      // 換算入数：換算入数を1とする
      setParams.put("ConversionFactor", new Integer(1).toString());

    }

    // ************************************ //
    // * 受入返品実績(アドオン)登録処理   * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvAndRtnTxns(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvAndRtnTxns

  /***************************************************************************
   * (発注受入詳細画面)OIF登録処理を行うメソッドです。
   * @param orderHeaderVORow 発注ヘッダ
   * @param orderDetailsTabVORow 発注明細
   * @param txnsId 取引ID
   * @param groupId グループID
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insOpenIf(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;

    // ************************************** //
    // * 受入ヘッダOIF登録処理              * //
    // ************************************** //
    retHashMap = insRcvHeadersIf(
                   orderHeaderVORow,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");

    // 登録・訂正処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
      return retHashMap;
    }

    Number headerInterfaceId = (Number)retHashMap.get("HeaderInterfaceId");
    groupId  = (Number)retHashMap.get("GroupId");

    // ************************************** //
    // * 受入トランザクションOIF登録処理    * //
    // ************************************** //
    retHashMap = insRcvTransactionsIf(
                   orderHeaderVORow, 
                   orderDetailsTabVORow,
                   txnsId,
                   headerInterfaceId,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");
    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    // 登録処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;

    }


    // 品目がロット対象である場合
    Number lotCtl = (Number)orderDetailsTabVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * 品目ロットトランザクションOIF登録処理    * //
      // ******************************************** //
      retCode = insMtlTransactionLotsIf(
                  orderHeaderVORow, 
                  orderDetailsTabVORow,
                  interfaceTransactionId);

      // 登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }

    retHashMap.put("GroupId", groupId);
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // insOpenIf

  /***************************************************************************
   * (発注受入詳細画面)受入トランザクションOIF登録処理を行うメソッドです。
   * @param orderHeaderVORow 発注ヘッダ
   * @param orderDetailsTabVORow 発注明細
   * @param txnsId 取引ID
   * @param headerInterfaceId 受入ヘッダOIF.header_interface_id
   * @param groupId 受入ヘッダOIF.group_id
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insRcvTransactionsIf(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow,
    Number txnsId,
    Number headerInterfaceId,
    Number groupId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsTabVORow.getAttribute("ItemAmount"));

    // 受入返品数量(発注残数)
    /*String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // カンマを除去
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));*/

    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // カンマを除去
                               (String)orderDetailsTabVORow.getAttribute("OrderAmount"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double型へ変換

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注明細.納入先コード
    setParams.put("LocationCode",       orderHeaderVORow.getAttribute("LocationCode"));
    // 発注明細ID
    setParams.put("LineId",             orderDetailsTabVORow.getAttribute("LineId"));
    // 受入ヘッダOIFのGROUP_IDと同値を指定
    setParams.put("GroupId",            groupId);
    // 納入日(納入予定日)
    setParams.put("TxnsDate",           orderHeaderVORow.getAttribute("DeliveryDate"));
    // 発注明細.品目基準単位
    setParams.put("UnitMeasLookupCode", orderDetailsTabVORow.getAttribute("UnitMeasLookupCode"));  
    // 発注明細.品目ID(ITEM_ID)
    setParams.put("PlaItemId",          orderDetailsTabVORow.getAttribute("PlaItemId"));
    // 発注ヘッダ.発注ヘッダID
    setParams.put("HeaderId",           orderHeaderVORow.getAttribute("HeaderId"));
    // 発注ヘッダ.納入日
    setParams.put("DeliveryDate",       orderHeaderVORow.getAttribute("DeliveryDate"));
    // 受入返品実績(アドオン)の取引ID
    setParams.put("TxnsId",             txnsId);
    // 受入ヘッダOIFのINTERFACE_TRANSACTION_ID
    setParams.put("HeaderInterfaceId",  headerInterfaceId);


    // 換算が必要な場合
    if (conversionFlag)
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 受入数量を入数で換算
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {
      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }

    // ************************************ //
    // * 受入トランザクションOIF登録処理   * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvTransactionsIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvTransactionsIf

  /***************************************************************************
   * (発注受入詳細画面)品目ロットトランザクションOIF登録処理を行うメソッドです。
   * @param orderHeaderVORow 発注ヘッダ
   * @param orderDetailsTabVORow 発注明細
   * @param interfaceTransactionId 受入トランザクションOIF.interface_transaction_id
   * @return String 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String insMtlTransactionLotsIf(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsTabVORow.getAttribute("ItemAmount"));

    // 受入返品数量(発注残数)
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // カンマを除去
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double型へ変換

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注明細.ロットNo
    setParams.put("LotNo",              orderDetailsTabVORow.getAttribute("LotNo"));
    // 受入トランザクションOIFのINTERFACE_TRANSACTION_ID
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);

    // 換算が必要な場合
    if (conversionFlag) 
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 受入数量
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {
      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }

    // ******************************************* //
    // * 品目ロットトランザクションOIF登録処理   * //
    // ******************************************* //
    String retCode = XxpoUtility.insertMtlTransactionLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // insMtlTransactionLotsIf

  /***************************************************************************
   * (発注受入詳細画面)在庫数量API起動処理を行うメソッドです。
   * @param txnsId 取引ID
   * @param orderHeaderVORow 発注ヘッダ
   * @param orderDetailsTabVORow 発注明細
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void insIcTranCmp(
    Number txnsId,
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    setParams.put("LocationCode",       orderDetailsTabVORow.getAttribute("VendorStockWhse"));    // 保管場所(相手先在庫入庫先)
    setParams.put("ItemNo",             orderDetailsTabVORow.getAttribute("OpmItemNo"));          // 品目(OPM品目名)
    setParams.put("UnitMeasLookupCode", orderDetailsTabVORow.getAttribute("UnitMeasLookupCode")); // 品目基準単位
    setParams.put("LotNo",              orderDetailsTabVORow.getAttribute("LotNo"));              // ロット
    setParams.put("TxnsDate",           orderHeaderVORow.getAttribute("DeliveryDate"));           // 取引日(発注ヘッダ.納入日予定日)
    setParams.put("ReasonCode",         XxpoConstants.CTPTY_INV_SHIP_RSN);                        // 事由コード(XXPO_CTPTY_INV_SHIP_RSN)
    setParams.put("TxnsId",             txnsId);                                                  // 文書ソースID(受入返品実績(アドオン).取引ID)

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 受入返品数量(発注残数)
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // カンマを除去
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double型へ変換


    // 換算が必要な場合
    if (conversionFlag)
    {
      // 換算入数を取得
      String sItemAmount = XxcmnUtility.commaRemoval(
                             (String)orderDetailsTabVORow.getAttribute("ItemAmount"));
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 発注数量
      // 発注数量 * 入数 * (-1)
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount * (-1);


      // 受入数量(換算注意)
      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {
      // 受入数量 * (-1)
      dRcvRtnQuantity = dRcvRtnQuantity * (-1);

      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    }

    // 在庫数量APIを起動
    XxpoUtility.insertIcTranCmp(
      getOADBTransaction(),
      setParams);

  } // insIcTranCmp

  /***************************************************************************
   * (発注受入詳細画面)OPMロットMST更新処理を行うメソッドです。
   * @param orderHeaderVORow 発注ヘッダ
   * @param orderDetailsTabVORow 発注明細
   * @return String 更新処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String updIcLotsMstTxns(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow
  ) throws OAException
  {

    // ロットNoを取得
    String lotNo     = (String)orderDetailsTabVORow.getAttribute("LotNo");
    // OPM品目IDを取得
    Number opmItemId = (Number)orderDetailsTabVORow.getAttribute("OpmItemId");
    // OPMロットMST最終更新日を取得
    String lotLastUpdateDate   = (String)orderDetailsTabVORow.getAttribute("LotLastUpdateDate");
    // OPMロットMST.納入日(初回)
    Date firstTimeDeliveryDate = (Date)orderDetailsTabVORow.getAttribute("FirstTimeDeliveryDate");
    // OPMロットMST.納入日(最終)
    Date finalDeliveryDate     = (Date)orderDetailsTabVORow.getAttribute("FinalDeliveryDate");

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 発注ヘッダの納入予定日を取得     * //
    // ************************************ //
    Date deliveryDate = (Date)orderHeaderVORow.getAttribute("DeliveryDate");

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    setParams.put("LotNo", lotNo);
    setParams.put("ItemId", opmItemId);

    // OPMロットMST.納入日(初回)がブランク(Null)である、
    //   または、発注ヘッダ.納入予定日がOPMロットMST.納入日(初回)より過去日の場合
    if (XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, firstTimeDeliveryDate, deliveryDate))
    {
// 2009-01-16 v1.9 T.Yoshimoto Mod Start 本番#1006
      //setParams.put("FirstTimeDeliveryDate", deliveryDate.toString());    // 納入日(初回)
      setParams.put("FirstTimeDeliveryDate", XxcmnUtility.stringValue(deliveryDate));    // 納入日(初回)
// 2009-01-16 v1.9 T.Yoshimoto Mod End 本番#1006
    }

    // OPMロットMST.納入日(最終)がブランク(Null)である、
    //   または、発注ヘッダ.納入予定日がOPMロットMST.納入日(最終)より未来日の場合
    if (XxcmnUtility.isBlankOrNull(finalDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, deliveryDate, finalDeliveryDate))
    {
// 2009-01-16 v1.9 T.Yoshimoto Mod Start 本番#1006
      //setParams.put("FinalDeliveryDate", deliveryDate.toString());       // 納入日(最終)
      setParams.put("FinalDeliveryDate", XxcmnUtility.stringValue(deliveryDate));       // 納入日(最終)
// 2009-01-16 v1.9 T.Yoshimoto Mod End 本番#1006

    }

    // ****************** //
    // * 更新処理       * //
    // ****************** //
    XxpoUtility.updateIcLotsMstTxns2(
      getOADBTransaction(),
      setParams);

    return XxcmnConstants.RETURN_SUCCESS;

  } // updIcLotsMstTxns

  /***************************************************************************
   * (発注受入詳細画面)発注ヘッダ.ステータス変更を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chgStatus()
  throws OAException
  {
    // 発注ヘッダVOを取得
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // 現在のステータスコードを取得
    String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");
    // 発注ヘッダIDを取得
    Number headerId = (Number)orderHeaderVORow.getAttribute("HeaderId");

    // 発注ヘッダに紐付く全ての発注明細の数量確定フラグが'Y'であるかを確認
    String chkAllFinDecisionAmountFlg = XxpoUtility.chkAllFinDecisionAmountFlg(
                                          getOADBTransaction(),
                                          headerId);

    // 発注ヘッダに紐付く全ての発注明細の数量確定フラグが'Y'の場合
    if (XxcmnConstants.STRING_Y.equals(chkAllFinDecisionAmountFlg))
    {

      // 更新処理(ステータスコード：数量確定済(20))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_FINISH_DECISION_AMOUNT,  // 数量確定済(20)
        headerId);                                    // 発注ヘッダID

    // 現在のステータスが、発注作成済(20)の場合
    } else if (XxpoConstants.STATUS_FINISH_ORDERING_MAKING.equals(statusCode)) 
    {

      // 更新処理(ステータスコード：受入あり(15))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_REPUTATION_CASE, // 受入あり(15)
        headerId);                            // 発注ヘッダID

    }

  } // chgStatus

  /***************************************************************************
   * (発注受入入力画面)初期化処理を行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void initialize3(
    HashMap searchParams
  ) throws OAException
  {

    // ******************************************* //
    // * 発注受入入力:発注受入入力PVO 空行取得   * //
    // ******************************************* //
    OAViewObject orderReceiptMakePVO = getXxpoOrderReceiptMakePVO1();

    // 1行もない場合、空行作成
    if (!orderReceiptMakePVO.isPreparedForExecution())
    {
      // 1行もない場合、空行作成
      orderReceiptMakePVO.setMaxFetchSize(0);
      orderReceiptMakePVO.executeQuery();
      orderReceiptMakePVO.insertRow(orderReceiptMakePVO.createRow());
    }

    // 1行目を取得
    OARow orderReceiptMakePVORow = (OARow)orderReceiptMakePVO.first();

    // キー値をセット
    orderReceiptMakePVORow.setAttribute("RowKey", new Number(1));
    // 起動条件をセット
    orderReceiptMakePVORow.setAttribute("pStartCondition", (String)searchParams.get("startCondition"));
    // 発注番号をセット
    orderReceiptMakePVORow.setAttribute("pHeaderNumber",   (String)searchParams.get("headerNumber"));
    // 明細番号をセット
    orderReceiptMakePVORow.setAttribute("pLineNumber",     (String)searchParams.get("lineNumber"));


    // ************************************** //
    // * 発注受入入力:発注明細VO 空行取得   * //
    // ************************************** //
    XxpoOrderDetailsVOImpl orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = null;

    // 検索実施
    orderDetailsVO.initQuery(searchParams);

    // データが取得できない場合、エラーページへ遷移する
    if (orderDetailsVO.getRowCount() == 0)
    {
      orderReceiptMakePVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500,
                  null,
                  OAException.ERROR,
                  null);
    }

    orderDetailsVORow = (OARow)orderDetailsVO.first();


    // ************************************** //
    // * 発注受入入力:受入明細VO 空行取得   * //
    // ************************************** //
    XxpoReceiptDetailsVOImpl receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // 検索実施
    receiptDetailsVO.initQuery(searchParams);

    // ***************************************** //
    // * 発注受入入力:受入明細VO 空行追加      * //
    // ***************************************** //
    // 明細.金額確定フラグを取得
    String moneyDecisionFlag = (String)orderDetailsVORow.getAttribute("MoneyDecisionFlag");

    // 明細金額確定フラグが"金額確定済"(Y)でない場合
    if (!XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
    {

      receiptDetailsVORow = (OARow)receiptDetailsVO.last();

      // 初回受入の場合
      if (receiptDetailsVORow == null) 
      {
        addRow();

      // 初回受入以降の場合
      } else
      {
        // 新規作成レコードフラグを取得
        Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

        // 納入日を取得
        Date deliveryDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");

        // 新規作成で無い場合、新規行を追加
        if (!(XxcmnUtility.isBlankOrNull(deliveryDate))
          && ((XxcmnUtility.isBlankOrNull(newRowFlag))
          || (!newRowFlag.booleanValue())))
        {
          addRow();

        }

      }
    }

    // ***************************************** //
    // * 発注受入入力:受入明細VO 入力制御      * //
    // ***************************************** //
    if (receiptDetailsVO.getRowCount() > 0) 
    {
    
      // 受入明細の入力制御を実施
      readOnlyChangedReceiptDetails();
    }
  } // initialize3

  /**************************************************************************
   * (発注受入入力画面)終了処理を行うメソッドです。
   * @param params 検索パラメータ用HashMap
   *************************************************************************
   */
  public void doEndOfProcess(
    HashMap params
  ) throws OAException
  {
    HashMap searchParams = new HashMap();
    
    // 発注番号をセット
    searchParams.put("headerNumber", params.get("pHeaderNum"));
    // 明細番号をセット
    searchParams.put("lineNumber", params.get("pChangedLineNum"));

    XxpoReceiptDetailsVOImpl receiptDetailsVO = getXxpoReceiptDetailsVO1();

    receiptDetailsVO.initQuery(searchParams);  

  }

  /***************************************************************************
   * (発注受入入力画面)受入明細の入力制御を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void readOnlyChangedReceiptDetails() throws OAException
  {

    // 発注受入入力:発注明細VO取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 発注受入入力:受入明細VO取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // 発注受入入力:発注受入入力PVO取得
    OAViewObject orderReceiptMakePVO = getXxpoOrderReceiptMakePVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)orderReceiptMakePVO.first();


    // ************************** //
    // * 初期化                 * //
    // ************************** //
    readOnlyRow.setAttribute("ApplyReadOnly", Boolean.FALSE);


    // ********************************** //
    // * 金額確定フラグによる項目制御   * //
    // ********************************** //
    // 明細.金額確定フラグを取得
    String moneyDecisionFlag = (String)orderDetailsVORow.getAttribute("MoneyDecisionFlag");


    // ************************** //
    // * (明細)納入日項目制御   * //
    // ************************** //
    receiptDetailsVO.first();

    // 現在行が取得できる間、処理を繰り返す
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // 初期化
      receiptDetailsVORow.setAttribute("ReceiptDetailsReadOnly", Boolean.FALSE);

      // 新規作成レコードフラグを取得
      Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

      // 納入日を取得
      Date deliveryDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");

      // 新規作成で無い場合は、項目制御を実施
      if (!(XxcmnUtility.isBlankOrNull(deliveryDate))
        && ((XxcmnUtility.isBlankOrNull(newRowFlag))
        || (!newRowFlag.booleanValue())))
      {
        receiptDetailsVORow.setAttribute("TxnsDateReadOnly", Boolean.TRUE);
        receiptDetailsVORow.setAttribute("NewRowFlag", Boolean.FALSE);

        // *********************************** //
        // *  納入日クローズによる項目制御   * //
        // *********************************** //
        // 明細.納入日がクローズの場合
        if (XxpoUtility.chkStockClose(
              getOADBTransaction(), // トランザクション
              deliveryDate))        // 明細.納入日
        {

          // 受入明細の受入数量/摘要を読取専用に変更
          receiptDetailsVORow.setAttribute("ReceiptDetailsReadOnly", Boolean.TRUE);

        }
      }
      
      // *********************************** //
      // *  金額確定フラグによる項目制御   * //
      // *********************************** //
      // 明細金額確定フラグが"金額確定済"(Y)の場合
      if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
      {

        // 受入明細の受入数量/摘要を読取専用に変更
        receiptDetailsVORow.setAttribute("ReceiptDetailsReadOnly", Boolean.TRUE);
      }

      receiptDetailsVO.next();
    }


    // ***************************************** //
    // *  金額確定フラグによる適用ボタン制御   * //
    // ***************************************** //
    // 明細金額確定フラグが"金額確定済"(Y)の場合
    if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
    {
      // 適用/行挿入ボタンを無効に変更
      readOnlyRow.setAttribute("ApplyReadOnly", Boolean.TRUE);

    }

  } // readOnlyChangedReceiptDetails

  /***************************************************************************
   * (発注受入入力画面)登録・更新前チェック処理を行います。
   * @return HashMap OA例外リスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap dataCheck2() throws OAException
  {
    // OA例外リストを生成します。
    HashMap messageCode = new HashMap();

// 2011-06-01 K.Kubo Add Start
    // 発注受入詳細:発注ヘッダVO取得
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);

    // 発注ヘッダIDを取得
    Number headerId = (Number)orderHeaderVORow.getAttribute("HeaderId");

    // ************************ //
    // * 仕入実績情報チェック * //
    // ************************ //
    String retFlag = XxpoUtility.chkStockResult(
                                    getOADBTransaction(),     // トランザクション
                                    headerId                  // 発注ヘッダID
                      );
    // 同一データが存在する場合（エラーが返ってきた場合）
    if (!XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
    {
      // エラーメッセージを追加
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            orderHeaderVO.getName(),
                            orderHeaderVORow.getKey(),
                            "HeaderId",
                            headerId,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10294));
    }

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

// 2011-06-01 K.Kubo Add End

    // ************************************ //
    // * 処理1:共通項目入力値チェック     * //
    // ************************************ //
    messageTextCommonCheck();

    // 初回受入チェック(true:初回, false:訂正処理)
    if (firstTimeCheck())
    {

      // ********************************************* //
      // * 処理2～4:(初)受入引当可能数チェック       * //
      // ********************************************* //
      reservedQuantityCheck(1, messageCode);

    // 訂正処理
    } else
    {

      // ********************************************* //
      // * 処理6-1～2:(訂)受入引当可能数チェック     * //
      // ********************************************* //
      reservedQuantityCheck(2, messageCode);

    }

    return messageCode;
  } // dataCheck2

  /***************************************************************************
   * (発注受入入力)登録・更新処理を行います。
   * @return HashMap 登録更新処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap apply2() throws OAException
  {

    // 登録更新処理結果
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;
    // グループID
    String[] groupId = null;

    // 初回受入チェック(true:初回, false:訂正処理)
    if (firstTimeCheck())
    {

      // *********************************************** //
      // * 処理5-1～5-2:受入情報を新規登録事前チェック * //
      // *********************************************** //
      chkInitialRegistration();

      // *********************************************** //
      // * 処理5-3～5-8:初回受入登録処理               * //
      // *********************************************** //
      retCode = initialRegistration2();

    // 訂正処理
    } else
    {
// 20081104 v1.6 yoshimoto Add Start
      // *********************************************** //
      // * 処理5-1～5-2:受入情報を新規登録事前チェック * //
      // *********************************************** //
      chkInitialRegistration();
// 20081104 v1.6 yoshimoto Add End

      // ********************************************* //
      // * 処理6-3～6-7:訂正データ登録処理           * //
      // ********************************************* //
      retHashMap = correctDataRegistration();
      retCode = (String)retHashMap.get("RetFlag");

    }

    // 登録処理更新結果が正常でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
      return retHashMap;
    }

    // ********************************************** //
    // * 処理5-7,7:発注ステータス変更処理           * //
    // ********************************************** //
    chgStatus2();

    // 上記までの登録更新処理が正常終了

    // 新規行フラグを初期化
    chgNewRowFlag();

    // 全ての処理が正常に終了している場合
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
    return retHashMap;

  } // apply2

  /***************************************************************************
   * (発注受入入力画面)共通項目入力値チェックを行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextCommonCheck() throws OAException
  {

    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    
    // ********************************** //
    // * 処理1:入力項目チェックを実施   * //
    // *   1-1:必須項目入力チェック     * //
    // *   1-2:受入数量入力値チェック   * //
    // *   1-3:納入日クローズチェック   * //
    // ********************************** //
    messageTextInputCheck(exceptions);

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

  } // messageTextCommonCheck

  /***************************************************************************
   * (発注受入入力画面)項目入力値チェックを行うメソッドです。
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextInputCheck(
    ArrayList exceptions
  ) throws OAException
  {
    // 発注受入入力:受入明細VO取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // 1行目
    receiptDetailsVO.first();

    while(receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // 行単位での必須項目入力チェックを実施
      messageTextInputRowCheck(receiptDetailsVO,
                               receiptDetailsVORow,
                               exceptions);

      receiptDetailsVO.next();

    }

  } // messageTextInputCheck

  /***************************************************************************
   * (発注受入入力画面)行単位で必須項目入力チェックを行うメソッドです。
   * @param checkVo チェック対象VO
   * @param checkRow チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextInputRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException
  {

    // 受入情報ReadOnlyフラグを取得
    Boolean receiptDetailsReadOnly = (Boolean)checkRow.getAttribute("ReceiptDetailsReadOnly");

    // 受入数量を取得
    String rcvRtnQuantity = (String)checkRow.getAttribute("RcvRtnQuantity");
    
    // 納入日を取得
    Date txnsDate         = (Date)checkRow.getAttribute("TxnsDate");
    
    // 更新フラグを取得
    Boolean newRowFlag    = (Boolean)checkRow.getAttribute("NewRowFlag");


    // ************************************ //
    // * 処理1-1:必須項目入力チェック     * //
    // ************************************ //
    // 受入数量が編集可能な場合、受入入数チェック
    if (!receiptDetailsReadOnly.booleanValue())
    {
    
      // 受入数量が未入力の場合はエラー
      if (XxcmnUtility.isBlankOrNull(rcvRtnQuantity))
      {

        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_RCV_RTN_QUANTITYT);

        // エラーメッセージを追加
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "RcvRtnQuantity",
                              rcvRtnQuantity,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10096,
                              tokens));

      } else
      {

        // ************************************ //
        // * 処理1-2:受入数量入力値チェック   * //
        // ************************************ //
        // 行単位での受入数量入力値チェックを実施
        messageTextQuantityRowCheck(checkVo,
                                    checkRow,
                                    exceptions);
      }
    }


    // 納入日が編集可能な場合、納入日チェック
    if (newRowFlag.booleanValue())
    {
      // 納入日が未入力の場合はエラー
      if (XxcmnUtility.isBlankOrNull(txnsDate))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_TXNS_DATE);
        
        // エラーメッセージを追加
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "TxnsDate",
                              txnsDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10096,
                              tokens));

      // 納入日が入力されている場合
      } else
      {

        // ************************************ //
        // * 処理1-3:納入日クローズチェック   * //
        // ************************************ //
        // 納入日が納入日クローズの場合はエラー
        if (XxpoUtility.chkStockClose(
          getOADBTransaction(),
          txnsDate))
        {
          // エラーメッセージを追加
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                checkVo.getName(),
                                checkRow.getKey(),
                                "TxnsDate",
                                txnsDate,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10140));
        }
      }
    }
  } // messageTextInputRowCheck

  /***************************************************************************
   * (発注受入入力画面)行単位で受入数量入力値チェックを行うメソッドです。
   * @param checkVo チェック対象VO
   * @param checkRow チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextQuantityRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException
  {

    // 受入情報ReadOnlyフラグを
    Boolean receiptDetailsReadOnly = (Boolean)checkRow.getAttribute("ReceiptDetailsReadOnly");

    // 受入数量を取得
    String rcvRtnQuantity = (String)checkRow.getAttribute("RcvRtnQuantity");

    // 納入日を取得
    Date txnsDate         = (Date)checkRow.getAttribute("TxnsDate");

    // 更新フラグを取得
    Boolean newRowFlag    = (Boolean)checkRow.getAttribute("NewRowFlag");

    // ************************************ //
    // * 処理1-2:受入数量入力値チェック   * //
    // ************************************ //
    // 受入数量が編集可能な場合、受入入数チェック
    if (!receiptDetailsReadOnly.booleanValue())
    {
      // 受入数量が0未満の場合はエラー
      if (!XxcmnUtility.isBlankOrNull(rcvRtnQuantity))
      {
        // 数値でない場合はエラー
        if (!XxcmnUtility.chkNumeric(XxcmnUtility.commaRemoval(rcvRtnQuantity), 9, 3))
        {

          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                checkVo.getName(),
                                checkRow.getKey(),
                                "RcvRtnQuantity",
                                rcvRtnQuantity,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10001));

        // 0以下はエラー
        } else if(!XxcmnUtility.chkCompareNumeric(2, XxcmnUtility.commaRemoval(rcvRtnQuantity), "0"))
        {
          // エラーメッセージトークン取得
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY,
                                       XxpoConstants.TOKEN_NAME_RCV_RTN_QUANTITYT);

          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                checkVo.getName(),
                                checkRow.getKey(),
                                "RcvRtnQuantity",
                                rcvRtnQuantity,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10068,
                                tokens));

        }
      }
    }
  } // messageTextQuantityRowCheck

  /***************************************************************************
   * (発注受入入力画面)初回受入であるかチェックを行うメソッドです。
   * @return boolean true:初回、false:訂正
   * @throws OAException OA例外
   ***************************************************************************
   */
  public boolean firstTimeCheck() throws OAException
  {
    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = (OARow)receiptDetailsVO.first();

    // 新規行フラグを取得
    Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

    // 受入明細VOの1行目が保持する新規行フラグが新規(true)の場合
    if (!(XxcmnUtility.isBlankOrNull(newRowFlag))
      && (newRowFlag.booleanValue()))
    {
      return true;
    }

    return false;

  } // firstTimeCheck
  
  /***************************************************************************
   * (発注受入入力画面)受入引当可能数チェックを行うメソッドです。
   * @param sw チェック切り替えスイッチ(1:初回、2:訂正)
   * @param messageCode エラーコードリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void reservedQuantityCheck(
    int sw,
    HashMap messageCode
  ) throws OAException
  {

    // ********************************** //
    // * 発注明細情報を取得             * //
    // ********************************** //
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 発注明細に紐付くOPM品目IDを取得
    Number opmItemId       = (Number)orderDetailsVORow.getAttribute("OpmItemId");

    // 発注明細に紐付く納入先コードを取得
    String locationCode    = (String)orderDetailsVORow.getAttribute("LocationCode");

    // 発注明細に紐付くLotIdを取得
    Number lotId           = (Number)orderDetailsVORow.getAttribute("LotId");

    // 発注明細に紐付くVendorStockWhseを取得
    String vendorStockWhse = (String)orderDetailsVORow.getAttribute("VendorStockWhse");


    // ************************************* //
    // * 受入明細情報を取得                * //
    // ************************************* //
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow     = (OARow)receiptDetailsVO.first();


    // ************************************* //
    // * 引当可能数量を取得                * //
    // *   paramsRet(0) : 有効日引当可能数 * //
    // *   paramsRet(1) : 総引当可能数     * //
    // ************************************* //
// 20080630 yoshimoto mod Start
    HashMap paramsRet = XxpoUtility.getReservedQuantity(
                                      getOADBTransaction(),
                                      opmItemId,            // OPM品目ID
                                      locationCode,         // 納入先コード
                                      lotId,               // ロットID
                                      "");
// 20080630 yoshimoto mod End

    // ************************************* //
    // * (相手先倉庫)引当可能数量を取得    * //
    // *   paramsRet(0) : 有効日引当可能数 * //
    // *   paramsRet(1) : 総引当可能数     * //
    // ************************************* //
    HashMap paramsRet2 = new HashMap();

// 20080627 Upd Start
    // 生産実績処理タイプを取得
//    String productResultType = (String)orderDetailsVORow.getAttribute("ProductResultType");
    // 生産実績処理タイプが相手先在庫(1)の場合
//    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
    // 発注区分を取得
    String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");

    // 発注区分が相手先在庫である場合
    if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
    {
// 20080627 End
// 20080630 yoshimoto mod Start
      paramsRet2 = XxpoUtility.getReservedQuantity(
                                 getOADBTransaction(),
                                 opmItemId,            // OPM品目ID
                                 vendorStockWhse,      // 相手先在庫入庫先
                                 lotId,                // ロットID
                                 XxpoConstants.PO_TYPE_3);       // 発注区分
// 20080630 yoshimoto mod End
    }

    // swが初回受入処理の場合
    if (sw == 1)
    {

      // (初)受入引当可能数チェック
      firstTimeReservedQtyCheck(paramsRet, paramsRet2, messageCode);

    // swが受入訂正処理の場合
    } else
    {

      // (訂)受入引当可能数チェック
      correctReservedQtyCheck(paramsRet, paramsRet2, messageCode);

    }
 
  } // reservedQuantityCheck

  /***************************************************************************
   * (発注受入入力画面)引当可能数チェックを行うメソッドです。(初回受入)
   * @param reservedQuantity 引当可能数(有効日引当可能数、総引当可能数)
   * @param reservedQuantity2 相手先倉庫引当可能数(有効日引当可能数、総引当可能数)
   * @param messageCode エラーコードリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void firstTimeReservedQtyCheck(
    HashMap reservedQuantity,
    HashMap reservedQuantity2,
    HashMap messageCode
  ) throws OAException
  {

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;


    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String itemAmount = XxcmnUtility.commaRemoval(
                          (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * 発注数量を取得                   * //
    // ************************************ //
    String sOrderAmount = XxcmnUtility.commaRemoval(
                            (String)orderDetailsVORow.getAttribute("OrderAmount"));

    // 換算が必要な場合は、在庫入数で乗算
    if (conversionFlag)
    {
      double dOrderAmount = Double.parseDouble(sOrderAmount) * Double.parseDouble(itemAmount);
      sOrderAmount = Double.toString(dOrderAmount);
    }


    // ************************************ //
    // * 画面.受入数量(総計)を取得        * //
    // ************************************ //
    double rcvRtnQtyTotal = 0.000;

    // 納入日過去日付チェックフラグ
    boolean dateOfPastFlag = false;

    // 納入予定日
    Date DeliveryDate = (Date)orderDetailsVORow.getAttribute("DeliveryDate");

    // 受入明細.納入日
    Date txnsDate = null;

    receiptDetailsVO.first();

    // 受入明細行が取得できる間、処理を繰り返す
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();
      String sRcvRtnQty   = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

      if (!XxcmnUtility.isBlankOrNull(sRcvRtnQty))
      {
        // カンマ及び小数点を除去
        sRcvRtnQty = XxcmnUtility.commaRemoval(sRcvRtnQty);

        // カンマ及び小数点を除去した値を加算
        rcvRtnQtyTotal += Double.parseDouble(sRcvRtnQty);
        
      }

      txnsDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");
      
      // 納入日が過去日付の場合(納入日 > 納入予定日)
      if (XxcmnUtility.chkCompareDate(1, txnsDate, DeliveryDate))
      {
        // 過去日付の明細が存在する
        dateOfPastFlag = true;
      }

      receiptDetailsVO.next();

    }

    // 換算が必要な場合は、在庫入数で乗算
    if (conversionFlag)
    {
      rcvRtnQtyTotal = rcvRtnQtyTotal * Double.parseDouble(itemAmount);
    }

// 20080825 H.Itou Add Start
    BigDecimal bRcvRtnQtyTotal = new BigDecimal(String.valueOf(rcvRtnQtyTotal));
// 20080825 H.Itou Add End

    // 有効日ベース引当可能数
    Object inTimeQty = reservedQuantity.get("InTimeQty");
    // 総引当可能数
    Object totalQty  = reservedQuantity.get("TotalQty");


    // ************************************ //
    // * 処理2:受入後倒しチェック         * //
    // ************************************ //
    // 過去日付の明細が存在する場合
    if (dateOfPastFlag)
    {
      // 『発注数量 > 有効日ベース引当可能数』または、『発注数量 > 総引当可能数』
      if ((XxcmnUtility.chkCompareNumeric(1, sOrderAmount, inTimeQty.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, totalQty.toString())))
      {

        // 受入日後倒しの確認(警告)
        // メッセージコードを設定
        messageCode.put(XxcmnConstants.XXCMN10112, XxcmnConstants.XXCMN10112);

      }
    }


    // ************************************ //
    // * 処理3:受入減数計上チェック       * //
    // ************************************ //
    // 受入数量が発注数量を下回る場合
// 20080825 H.Itou Mod Start
//    if (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, Double.toString(rcvRtnQtyTotal)))
    if (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, bRcvRtnQtyTotal))
// 20080825 H.Itou Mod End
    {
      // 減数数量 = (総計)発注数量 - (画面.総計)受入数量
      double subtracterAmount = Double.parseDouble(sOrderAmount) - rcvRtnQtyTotal;

// 20080825 H.Itou Add Start
      BigDecimal bSubtracterAmount = new BigDecimal(String.valueOf(subtracterAmount));
// 20080825 H.Itou Add End

      //  『減数数量 > 有効日ベース引当可能数』または、『減数数量 > 総引当可能数』
// 20080825 H.Itou Mod Start
//      if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(subtracterAmount), inTimeQty.toString()))
//        || (XxcmnUtility.chkCompareNumeric(1, Double.toString(subtracterAmount), totalQty.toString())))
      if ((XxcmnUtility.chkCompareNumeric(1, bSubtracterAmount, inTimeQty.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, bSubtracterAmount, totalQty.toString())))
// 20080825 H.Itou Mod End
      {

        // 受入減数計上による供給不可の確認(警告)
        // 処理2において、XXCMN10112が設定されていない場合
        if (messageCode.size() == 0)
        {
          // メッセージコードを設定
          messageCode.put(XxcmnConstants.XXCMN10112, XxcmnConstants.XXCMN10112);
        }

      }
    }


    // ************************************ //
    // * 処理4:受入増数計上チェック       * //
    // ************************************ //
// 20080627 Upd Start
    // 生産実績処理タイプを取得
//    String productResultType = (String)orderDetailsVORow.getAttribute("ProductResultType");
    
    // 受入数量が発注数量を上回る且つ、生産実績処理タイプが相手先在庫(1)の場合
//    if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(rcvRtnQtyTotal), sOrderAmount))
//      && (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)))
    // 発注区分を取得
    String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");
// 20080825 H.Itou Mod Start
//    if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(rcvRtnQtyTotal), sOrderAmount))
    if ((XxcmnUtility.chkCompareNumeric(1, bRcvRtnQtyTotal, sOrderAmount))
// 20080825 H.Itou Mod End
      && (XxpoConstants.PO_TYPE_3.equals(orderDivision)))
    {
// 20080627 Upd End
      // 増数数量 = (画面.総計)受入数量 - (総計)発注数量
      double masAmount = rcvRtnQtyTotal - Double.parseDouble(sOrderAmount);

      // (相手先在庫入庫先)有効日ベース引当可能数
      Object inTimeQty2 = reservedQuantity2.get("InTimeQty");
      // (相手先在庫入庫先)総引当可能数
      Object totalQty2  = reservedQuantity2.get("TotalQty");

      //  『増数数量 > 有効日ベース引当可能数』または、『増数数量 > 総引当可能数』
      if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(masAmount), inTimeQty2.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, Double.toString(masAmount), totalQty2.toString())))
      {

        // 受入増数計上による相手先在庫の引当不可の確認(警告)
        // メッセージコードを設定
        messageCode.put(XxcmnConstants.XXCMN10110, XxcmnConstants.XXCMN10110);

      }
    }
  } // firstTimeReservedQtyCheck

  /***************************************************************************
   * (発注受入入力画面)引当可能数チェックを行うメソッドです。(訂正)
   * @param reservedQuantity 引当可能数(有効日引当可能数、総引当可能数)
   * @param reservedQuantity2 相手先倉庫引当可能数(有効日引当可能数、総引当可能数)
   * @param messageCode エラーコードリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void correctReservedQtyCheck(
    HashMap reservedQuantity,
    HashMap reservedQuantity2,
    HashMap messageCode
  ) throws OAException
  {

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;


    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String itemAmount = XxcmnUtility.commaRemoval(
                          (String)orderDetailsVORow.getAttribute("ItemAmount"));


    // ************************************ //
    // * (訂正)画面.受入数量(総計)を取得  * //
    // * 訂正前受入数量(総計)を取得       * //
    // ************************************ //
    double rcvRtnQtyTotal = 0.000;
    double quantityTotal  = 0.000;
    
    receiptDetailsVO.first();

    // 受入明細行が取得できる間、処理を繰り返す
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // 受入数量
      String sRcvRtnQty   = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

      // 訂正前受入数量
      Number nQuantity    = (Number)receiptDetailsVORow.getAttribute("Quantity");

      // 画面.受入数量の総計を算出
      if (!XxcmnUtility.isBlankOrNull(sRcvRtnQty))
      {
        // カンマ及び小数点を除去
        sRcvRtnQty = XxcmnUtility.commaRemoval(sRcvRtnQty);

        // カンマ及び小数点を除去した値を加算
        rcvRtnQtyTotal += Double.parseDouble(sRcvRtnQty);

      }

      // 訂正前受入数量の総計を算出
      if (!XxcmnUtility.isBlankOrNull(nQuantity))
      {
        quantityTotal += Double.parseDouble(XxcmnUtility.stringValue(nQuantity));
      }

      receiptDetailsVO.next();
    }

    // 換算が必要な場合は、在庫入数で乗算
    if (conversionFlag)
    {
      rcvRtnQtyTotal = rcvRtnQtyTotal * Double.parseDouble(itemAmount);

      quantityTotal  = quantityTotal  * Double.parseDouble(itemAmount);
    }

    // 有効日ベース引当可能数
    Object inTimeQty = reservedQuantity.get("InTimeQty");

    // 総引当可能数
    Object totalQty  = reservedQuantity.get("TotalQty");

    // ************************************ //
    // * 処理6-1:減数訂正チェック         * //
    // ************************************ //
    // 受入数量が訂正前数量を下回る場合
    BigDecimal bQuantityTotal = new BigDecimal(String.valueOf(quantityTotal));
    BigDecimal bRcvRtnQtyTotal = new BigDecimal(String.valueOf(rcvRtnQtyTotal));

    if (XxcmnUtility.chkCompareNumeric(1, bQuantityTotal, bRcvRtnQtyTotal))
    {

      // 減数数量 = (総計)訂正前数量 - (画面.総計)訂正後受入数量
      double subtracterAmount = quantityTotal - rcvRtnQtyTotal;

      // 『減数数量 > 有効日ベース引当可能数』または、『減数数量 > 総引当可能数』
      BigDecimal bSubtracterAmount = new BigDecimal(String.valueOf(subtracterAmount));
      
      if ((XxcmnUtility.chkCompareNumeric(1, bSubtracterAmount, inTimeQty.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, bSubtracterAmount, totalQty.toString())))
      {

        // 減数訂正による供給不可の確認(警告)
        // 処理2において、XXCMN10112が設定されていない場合
        if (messageCode.size() == 0)
        {
          // メッセージコードを設定
          messageCode.put(XxcmnConstants.XXCMN10112, XxcmnConstants.XXCMN10112);
        }

      }
    }

    // ************************************ //
    // * 処理6-2:増数訂正チェック         * //
    // ************************************ //
// 20080627 Upd Start
    // 生産実績処理タイプを取得
//    String productResultType = (String)orderDetailsVORow.getAttribute("ProductResultType");

    // 受入数量が訂正前受入数量を上回る且つ、生産実績処理タイプが相手先在庫(1)の場合
//    if ((XxcmnUtility.chkCompareNumeric(1, bRcvRtnQtyTotal, bQuantityTotal))
//      && (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)))
    // 発注区分を取得
    String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");

    if ((XxcmnUtility.chkCompareNumeric(1, bRcvRtnQtyTotal, bQuantityTotal))
      && (XxpoConstants.PO_TYPE_3.equals(orderDivision)))
    {
// 20080627 Upd End
      // 増数数量 = (画面.総計)受入数量 - (総計)訂正前受入数量
      double masAmount = rcvRtnQtyTotal- quantityTotal;

      // (相手先在庫入庫先)有効日ベース引当可能数
      Object inTimeQty2 = reservedQuantity2.get("InTimeQty");

      // (相手先在庫入庫先)総引当可能数
      Object totalQty2  = reservedQuantity2.get("TotalQty");

      // 『増数数量 > 有効日ベース引当可能数』または、『増数数量 > 総引当可能数』
      BigDecimal bMasAmount = new BigDecimal(String.valueOf(masAmount));
      if ((XxcmnUtility.chkCompareNumeric(1, bMasAmount, inTimeQty2.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, bMasAmount, totalQty2.toString())))
      {

        // 増数訂正による相手先在庫の引当不可の確認(警告)
        // メッセージコードを設定
        messageCode.put(XxcmnConstants.XXCMN10110, XxcmnConstants.XXCMN10110);

      }
    }
  } // correctReservedQtyCheck

  /***************************************************************************
   * (発注受入入力画面)新規登録事前チェックを行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkInitialRegistration() throws OAException
  {
    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 納入予定日を取得
    Date deliveryDate = (Date)orderDetailsVORow.getAttribute("DeliveryDate");
    String subStrDeliveryDate = deliveryDate.toString().substring(0,7);

    // システム日付を取得
    Date sysDate = XxpoUtility.getSysdate(getOADBTransaction());

// 20080523 del yoshimoto Start
/*
    // ************************************ //
    // * 処理5-1:未来日付チェック         * //
    // ************************************ //
    // 納入予定日が未来日でないか確認
    if (XxcmnUtility.chkCompareDate(1, deliveryDate, sysDate))
    {
      // エラーメッセージ出力
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10088);
    }
*/
// 20080523 del yoshimoto End

    // ************************************ //
    // * 処理5-1:未来日付チェック         * //
    // * 処理5-2:同一年月チェック         * //
    // ************************************ //
    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    receiptDetailsVO.first();

    ArrayList exceptions = new ArrayList();
    // 受入明細が取得できる間、処理を継続
    while(receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // 受入明細の納入日を取得
      Date txnsDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");
      String subStrTxnsDate = txnsDate.toString().substring(0,7);

// 20080523 add yoshimoto Start
      // 納入予定日が未来日でないか確認
      if (XxcmnUtility.chkCompareDate(1, txnsDate, sysDate))
      {
        // エラーメッセージ出力
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              receiptDetailsVO.getName(),
                              receiptDetailsVORow.getKey(),
                              "TxnsDate",
                              txnsDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10088));


// 20080523 add yoshimoto End

      // 納入日と、納入日予定日が同一年月で無い場合
      } else if (!subStrDeliveryDate.equals(subStrTxnsDate))
      {
        // エラーメッセージ出力
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              receiptDetailsVO.getName(),
                              receiptDetailsVORow.getKey(),
                              "TxnsDate",
                              txnsDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10061));

      }

      receiptDetailsVO.next();
    }

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);

    }

  } // chkInitialRegistration

  /***************************************************************************
   * (発注受入入力画面)新規登録を行うメソッドです。
   * @return String 登録処理結果(成功:グループID、失敗:xcmnConstants.RETURN_NOT_EXE)
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String initialRegistration2() throws OAException
  {
    // 登録処理結果
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // 合計受入数量
    double receiptAmountTotal = 0.000;

    // 取引ID
    Number txnsId = null;

    // グループID
    Number groupId = null;
    String retGroupId = null;

    receiptDetailsVO.first();

    // 受入明細が取得できる間、処理を継続
    while(receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();


      // ********************************************** //
      // * 処理5-4:受入返品実績(アドオン)登録処理     * //
      // ********************************************** //
      retHashMap = (HashMap)insRcvAndRtnTxns2(
                              orderDetailsVORow,
                              receiptDetailsVORow);

      retCode = (String)retHashMap.get("RetFlag");

      // 登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }

      // 受入返品実績(アドオン).取引IDを取得
      txnsId = (Number)retHashMap.get("TxnsId");

      // 受入数量を取得
      String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

      // カンマを除去
      rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);

      receiptAmountTotal += Double.parseDouble(rcvRtnQuantity);


      // 受入数量が0より多い場合
      if (XxcmnUtility.chkCompareNumeric(1, rcvRtnQuantity, "0"))
      {
        // ************************************************ //
        // * 処理5-3:受入オープンインタフェース登録処理   * //
        // ************************************************ //
        retHashMap = insOpenIf2(
                       orderDetailsVORow,
                       receiptDetailsVORow,
                       txnsId,
                       groupId);

        retCode = (String)retHashMap.get("RetFlag");
        retGroupId = retCode.toString();
        
        // 登録処理が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          return XxcmnConstants.RETURN_NOT_EXE;
        }

        // グループIDを退避
        groupId = (Number)retHashMap.get("GroupId");
        retGroupId = groupId.toString();
// 2009-01-27 v1.10 T.Yoshimoto Del Start
      //}
// 2009-01-27 v1.10 T.Yoshimoto Del End

        // ************************************ //
        // * 処理5-8:在庫数量API起動処理      * //
        // ************************************ //
        // 発注区分を取得
        String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");
  
        // 発注区分が相手先在庫である場合
        if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
        {
          insIcTranCmp2(XxcmnConstants.STRING_ZERO, // 処理モード(0:初回受入)
                        txnsId,                     // 取引ID
                        receiptDetailsVORow);       // 受入明細
        }
// 2009-01-27 v1.10 T.Yoshimoto Add Start
      }
// 2009-01-27 v1.10 T.Yoshimoto Add End

      receiptDetailsVO.next();
    }


    // *********************************** //
    // * 処理5-5:発注明細更新処理        * //
    // *********************************** //
    // ロック取得処理
    getDetailsRowLock((Number)orderDetailsVORow.getAttribute("LineId"));

    // 排他制御
    chkDetailsExclusiveControl(
      (Number)orderDetailsVORow.getAttribute("LineId"),
      (String)orderDetailsVORow.getAttribute("LastUpdateDate"));

    // 更新処理
    XxpoUtility.updateReceiptAmount(
      getOADBTransaction(),
      (Number)orderDetailsVORow.getAttribute("LineId"),
      receiptAmountTotal);


    // *********************************** //
    // * 処理5-6:ロット更新処理          * //
    // *********************************** //
    // 品目がロット対象である場合
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // 更新処理
      updIcLotsMstTxns2();

    }

    // ********************************************** //
    // * 処理8:受入取引処理を起動                   * //
    // ********************************************** //  
    // 受入数量が0より多い場合
    if (!XxcmnUtility.isBlankOrNull(groupId))
    {
      // OIF登録更新処理の場合
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      XxpoUtility.doRVCTP(
        getOADBTransaction(),
        retGroupId);
    }
    
    return XxcmnConstants.RETURN_SUCCESS;

  } // initialRegistration2

  /***************************************************************************
   * (発注受入入力画面)訂正データ登録を行うメソッドです。
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap correctDataRegistration() throws OAException
  {

    // 登録処理結果
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;

    // 取引ID
    Number txnsId = null;

    // グループID
// 2009-01-16 v1.16 T.Yoshimoto Add Start
    Number[] groupId;
// 2009-01-16 v1.16 T.Yoshimoto Add End

    // 返却用グループID
    String[] retGroupId = new String[2];

    // 合計訂正前受入数量
    double quantityTotal      = 0.000;

    // 合計受入数量
    double receiptAmountTotal = 0.000;

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    receiptDetailsVO.first();

    // 受入明細が取得できる間、処理を継続
    while(receiptDetailsVO.getCurrentRow() != null)
    {

// 2009-01-16 v1.16 T.Yoshimoto Add Start
      groupId = new Number[2];  // 配列初期化
// 2009-01-16 v1.16 T.Yoshimoto Add End

      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // 訂正処理時において、訂正前受入数量と受入数量に差分が無い場合は、訂正処理を中断
      String chkSubflag = chkSubRcvRtnQuantity(
                                orderDetailsVORow,
                                receiptDetailsVORow);


      // 現在行の取引IDを取得
      txnsId = (Number)receiptDetailsVORow.getAttribute("TxnsId");

      // 受入数量を取得
      String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
      // カンマを除去
      rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
      // 受入数量を合計受入数量に加算
      receiptAmountTotal += Double.parseDouble(rcvRtnQuantity);


      // 訂正前受入数量を取得
      Number quantity = (Number)receiptDetailsVORow.getAttribute("Quantity");
      // 訂正前受入数量を合計訂正前受入数量に加算
      if (!XxcmnUtility.isBlankOrNull(quantity))
      {
        quantityTotal += quantity.doubleValue();
        
      }

      // 新規作成レコードフラグを取得
      Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

      // 行挿入にて追加された行の場合
      if (newRowFlag.booleanValue())
      {

        // ********************************************** //
        // * 処理5-4:受入返品実績(アドオン)登録処理     * //
        // ********************************************** //
        retHashMap = (HashMap)insRcvAndRtnTxns2(
                                orderDetailsVORow, 
                                receiptDetailsVORow);

        retCode = (String)retHashMap.get("RetFlag");

        // 登録処理が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          return retHashMap;
        }

        // 受入返品実績(アドオン).取引IDを取得
        txnsId = (Number)retHashMap.get("TxnsId");

        // 受入数量が0より多い場合
        if (XxcmnUtility.chkCompareNumeric(1, rcvRtnQuantity, "0"))
        {
          // ************************************************ //
          // * 処理5-3:受入オープンインタフェース登録処理   * //
          // ************************************************ //
          retHashMap = insOpenIf2(
                         orderDetailsVORow,
                         receiptDetailsVORow,
                         txnsId,
                         groupId[0]);

          retCode = (String)retHashMap.get("RetFlag");
          retGroupId[0] = retCode.toString();
        
          // 登録処理が正常終了でない場合
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
          {
            return retHashMap;
          }

          // グループIDを退避
          groupId[0] = (Number)retHashMap.get("GroupId");
          retGroupId[0] = groupId[0].toString();

// 2009-01-27 v1.10 T.Yoshimoto Del Start
        //}
// 2009-01-27 v1.10 T.Yoshimoto Del End

          // ************************************ //
          // * 処理5-8:在庫数量API起動処理      * //
          // ************************************ //
          // 発注区分を取得
          String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");
  
          // 発注区分が相手先在庫である場合
          if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
          {
            insIcTranCmp2(XxcmnConstants.STRING_ZERO, // 処理モード(0:初回受入)
                          txnsId,                     // 取引ID
                          receiptDetailsVORow);       // 受入明細
          }
// 2009-01-27 v1.10 T.Yoshimoto Add Start
        }
// 2009-01-27 v1.10 T.Yoshimoto Add End

      // 更新レコードの場合
      } else
      {

        // 取引IDを基に、EBS標準.受入に登録済みであるか確認
        String inputFlag = XxpoUtility.chkRcvOifInput(
                             getOADBTransaction(),
                             txnsId);

        // 訂正前受入数量と受入数量に差分が無い場合は、OIF登録処理は行わない
        if (!"0".equals(chkSubflag)) 
        {
          // 受入OIFに登録済みである場合
          if (XxcmnConstants.STRING_Y.equals(inputFlag))
          {

            // ************************************************ //
            // * 処理6-3:受入オープンインタフェース訂正処理   * //
            // ************************************************ //
            // 受入数量
            String sRcvRtnQty   = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

            // 訂正前受入数量
            Number nQuantity    = (Number)receiptDetailsVORow.getAttribute("Quantity");

            // 増数訂正
            if ("1".equals(chkSubflag))
            {

              // ******************* //
              // * (1) OIF受入訂正 * //
              // ******************* //
              retHashMap = correctOpenIf(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[0]);

              retCode = (String)retHashMap.get("RetFlag");

              // 登録処理が正常終了でない場合
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // グループIDを退避
              groupId[0] = (Number)retHashMap.get("GroupId");
              
              retGroupId[0] = groupId[0].toString();

              // ******************* //
              // * (2)OIF搬送訂正  * //
              // ******************* //
              retHashMap = correctOpenIf2(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[1]);

              retCode = (String)retHashMap.get("RetFlag");

              // 登録処理が正常終了でない場合
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // グループIDを退避
              groupId[1] = (Number)retHashMap.get("GroupId");
              retGroupId[1] = groupId[1].toString();

            // 減数訂正
            } else 
            {

              // ******************* //
              // * (1)OIF搬送訂正  * //
              // ******************* //
              retHashMap = correctOpenIf2(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[0]);

              
              retCode = (String)retHashMap.get("RetFlag");

              // 登録処理が正常終了でない場合
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // グループIDを退避
              groupId[0] = (Number)retHashMap.get("GroupId");
              retGroupId[0] = groupId[0].toString();

              // ******************* //
              // * (2) OIF受入訂正 * //
              // ******************* //
              retHashMap = correctOpenIf(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[1]);


              retCode = (String)retHashMap.get("RetFlag");

              // 登録処理が正常終了でない場合
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // グループIDを退避
              groupId[1] = (Number)retHashMap.get("GroupId");
              retGroupId[1] = groupId[1].toString();
                            
            }

          // EBS標準.受入に登録済みでない場合
          } else
          {

// 2009-05-12 v1.12 T.Yoshimoto Add Start 本番#1458
            // 訂正前受入数量
            Number nQuantity    = (Number)receiptDetailsVORow.getAttribute("Quantity");

            if (XxcmnUtility.chkCompareNumeric(1, nQuantity, "0"))
            {
              // ロールバック
              XxpoUtility.rollBack(getOADBTransaction());

              // 発注受入入力:発注受入入力PVO取得
              OAViewObject orderReceiptMakePVO = getXxpoOrderReceiptMakePVO1();
              // 1行目を取得
              OARow readOnlyRow = (OARow)orderReceiptMakePVO.first();

              // 適用/行挿入ボタンを無効に変更
              readOnlyRow.setAttribute("ApplyReadOnly", Boolean.TRUE);

              //トークン生成
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN,
                                                         "受入取引処理中") };
                               
              // 処理起動エラー
              throw new OAException(XxcmnConstants.APPL_XXPO,
                                     XxpoConstants.XXPO10291,
                                     tokens);
            }
// 2009-05-12 v1.12 T.Yoshimoto Add End 本番#1458

            // 受入数量が0より多い場合
            if (XxcmnUtility.chkCompareNumeric(1, rcvRtnQuantity, "0"))
            {
              // ************************************************ //
              // * 処理6-4:受入オープンインタフェース登録処理   * //
              // ************************************************ //
              retHashMap = insOpenIf2(
                             orderDetailsVORow, 
                             receiptDetailsVORow,
                             txnsId,
                             groupId[0]);

              retCode = (String)retHashMap.get("RetFlag");

              // 登録処理が正常終了でない場合
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // グループIDを退避
              groupId[0] = (Number)retHashMap.get("GroupId");
              retGroupId[0] = groupId[0].toString();
            }
          }
        }

        // ********************************************** //
        // * 処理6-5:受入返品実績(アドオン)更新処理     * //
        // ********************************************** //
        // 受入数量が変更されている、又は、摘要が変更されている場合
        if (!"0".equals(chkSubflag) || chkUpdLineDescription(receiptDetailsVORow))
        {
          retCode = updRcvAndRtnTxns(
                      orderDetailsVORow,
                      receiptDetailsVORow);

          // 登録処理が正常終了でない場合
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
          {
            retHashMap.put("RetFlag", retCode);
            return retHashMap;
          }
        }
// 2009-01-27 v1.10 T.Yoshimoto Del Start
      //}
// 2009-01-27 v1.10 T.Yoshimoto Del End
  
        // 訂正前受入数量と受入数量に差分が無い場合は、在庫数量API起動処理は行わない
        if (!"0".equals(chkSubflag)) 
        {
          // ************************************ //
          // * 処理6-7:在庫数量API起動処理      * //
          // ************************************ //
          // 発注区分を取得
          String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");
  
          // 発注区分が相手先在庫である場合
          if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
          {
            insIcTranCmp2(XxcmnConstants.STRING_ONE, // 処理モード(1:訂正処理)
                          txnsId,                    // 取引ID
                          receiptDetailsVORow);      // 受入明細
          }
        }
// 2009-01-27 v1.10 T.Yoshimoto Add Start
      }
// 2009-01-27 v1.10 T.Yoshimoto Add End

      // ********************************************** //
      // * 処理8:受入取引処理を起動                   * //
      // ********************************************** //
      // OIF登録更新処理の場合
      if (!XxcmnUtility.isBlankOrNull(groupId[0]))
      {
        if (XxcmnUtility.isBlankOrNull(groupId[1])) 
        {
       
          retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

          retHashMap = XxpoUtility.doRVCTP(
                         getOADBTransaction(),
                         retGroupId[0]);

          String retFlag = (String)retHashMap.get("RetFlag");
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
          {           
            return retHashMap;
          }
          
        // OIF訂正処理の場合
        } else if (groupId.length > 1)
        {
// 2009-01-16 v1.16 T.Yoshimoto Mod Start
/*
          for (int i = 0; i < groupId.length; i++) 
          {
            retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

            retHashMap = XxpoUtility.doRVCTP(
                           getOADBTransaction(),
                           retGroupId[i]);

            String retFlag = (String)retHashMap.get("RetFlag");
            if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
            {
              return retHashMap;
            }
          }
*/
          retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

          retHashMap = XxpoUtility.doRVCTP2(
                         getOADBTransaction(),
                         retGroupId);

          String retFlag = (String)retHashMap.get("RetFlag");

          if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
          {
            return retHashMap;
          }
// 2009-01-16 v1.16 T.Yoshimoto Mod End
        }
      }
      
      receiptDetailsVO.next();

    }

    // *********************************** //
    // * 処理6-6:発注明細更新処理        * //
    // *********************************** //
    if (quantityTotal != receiptAmountTotal)
    {

      // ロック取得処理
      getDetailsRowLock((Number)orderDetailsVORow.getAttribute("LineId"));

      // 排他制御
      chkDetailsExclusiveControl(
        (Number)orderDetailsVORow.getAttribute("LineId"),
        (String)orderDetailsVORow.getAttribute("LastUpdateDate"));

      // 更新処理
      XxpoUtility.updateReceiptAmount(
        getOADBTransaction(),
        (Number)orderDetailsVORow.getAttribute("LineId"),
        receiptAmountTotal);

    }

    // 正常に処理された場合は、グループIDを返却
    retHashMap.put("GroupId", retGroupId);
    return retHashMap;

  } // correctDataRegistration


  /***************************************************************************
   * (発注受入入力画面)受入返品実績(アドオン)登録処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insRcvAndRtnTxns2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 実績区分
    setParams.put("TxnsType",              "1");
    // 受入返品番号
    setParams.put("RcvRtnNumber",          orderDetailsVORow.getAttribute("HeaderNumber"));
    // 元文書番号
    setParams.put("SourceDocumentNumber",  orderDetailsVORow.getAttribute("HeaderNumber"));
    // 取引先ID
    setParams.put("VendorId",              orderDetailsVORow.getAttribute("VendorId"));
    // 取引先コード
    setParams.put("VendorCode",            orderDetailsVORow.getAttribute("VendorCode"));
    // 入出庫先コード
    setParams.put("LocationCode",          orderDetailsVORow.getAttribute("LocationCode"));
    // 元文書明細番号
    setParams.put("SourceDocumentLineNum", orderDetailsVORow.getAttribute("LineNum"));
    // 受入返品明細番号
    setParams.put("RcvRtnLineNumber",      receiptDetailsVORow.getAttribute("RcvRtnLineNumber"));
    // 品目ID
    setParams.put("ItemId",                orderDetailsVORow.getAttribute("OpmItemId"));
    // 品目コード
    setParams.put("ItemCode",              orderDetailsVORow.getAttribute("OpmItemNo"));
    // ロットID
    setParams.put("LotId",                 orderDetailsVORow.getAttribute("LotId"));
    // ロットNo
    setParams.put("LotNumber",             orderDetailsVORow.getAttribute("LotNo"));
    // 取引日
    setParams.put("TxnsDate",              receiptDetailsVORow.getAttribute("TxnsDate"));

    // 受入返品数量
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // カンマを除去
                               (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double型へ変換

    setParams.put("RcvRtnQuantity",  new Double(dRcvRtnQuantity).toString());
    // 受入返品単位
    setParams.put("RcvRtnUom",       orderDetailsVORow.getAttribute("UnitName"));
    // 単位コード
    setParams.put("Uom",             orderDetailsVORow.getAttribute("UnitMeasLookupCode"));
    // 明細摘要
    setParams.put("LineDescription", receiptDetailsVORow.getAttribute("LineDescription"));
    // 直送区分
    setParams.put("DropshipCode",    orderDetailsVORow.getAttribute("DropshipCode"));
    // 単価
    setParams.put("UnitPrice",       orderDetailsVORow.getAttribute("UnitPrice"));
// 20080520 add yoshimoto Start
    // 発注部署コード
    setParams.put("DepartmentCode",  orderDetailsVORow.getAttribute("DepartmentCode"));
// 20080520 add yoshimoto End

    // 換算が必要な場合
    if (conversionFlag)
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 数量
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;
      setParams.put("Quantity", new Double(dRcvRtnQuantity).toString());

      // 換算入数：換算入数を発注明細.入数とする
      setParams.put("ConversionFactor", sItemAmount);


    // 換算が不要な場合
    } else
    {

      // 数量
      setParams.put("Quantity",         new Double(dRcvRtnQuantity).toString());
      // 換算入数：換算入数を1とする
      setParams.put("ConversionFactor", new Integer(1).toString());

    }

    // ************************************ //
    // * 受入返品実績(アドオン)登録処理   * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvAndRtnTxns(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvAndRtnTxns

  /***************************************************************************
   * (発注受入入力画面)受入返品実績(アドオン)訂正処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @return String 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String updRcvAndRtnTxns(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 取引ID
    setParams.put("TxnsId",           receiptDetailsVORow.getAttribute("TxnsId"));
    // 明細摘要
    setParams.put("LineDescription",  receiptDetailsVORow.getAttribute("LineDescription"));

    // 受入返品数量
    String sRcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    sRcvRtnQuantity = XxcmnUtility.commaRemoval(sRcvRtnQuantity);    // カンマを除去

    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);    // double型へ変換
    setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // 換算が必要な場合
    if (conversionFlag)
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 数量
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      setParams.put("Quantity", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {

      // 数量
      setParams.put("Quantity", new Double(dRcvRtnQuantity).toString());

    }

    // ************************************ //
    // * 受入返品実績(アドオン)更新処理   * //
    // ************************************ //
    // ロックの取得
    getRcvRtnRowLock((Number)receiptDetailsVORow.getAttribute("TxnsId"));

    // 排他制御
    chkRcvRtnExclusiveControl(
      (Number)receiptDetailsVORow.getAttribute("TxnsId"),
      (String)receiptDetailsVORow.getAttribute("LastUpdateDate"));

    String retCode = XxpoUtility.updateRcvAndRtnTxns(
                                       getOADBTransaction(),
                                       setParams);

    return retCode;

  } // updRcvAndRtnTxns

  /***************************************************************************
   * (発注受入入力画面)OIF登録処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param txnsId 取引ID
   * @param groupId グループID
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insOpenIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;


    // ************************************** //
    // * 受入ヘッダOIF登録処理(登録のみ)    * //
    // ************************************** //
    retHashMap = insRcvHeadersIf(
                   orderDetailsVORow,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");

    // 登録・訂正処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
      return retHashMap;
    }

    Number headerInterfaceId = (Number)retHashMap.get("HeaderInterfaceId");
    groupId  = (Number)retHashMap.get("GroupId");

    // ************************************** //
    // * 受入トランザクションOIF登録処理    * //
    // ************************************** //
    retHashMap = insRcvTransactionsIf2(
                   orderDetailsVORow, 
                   receiptDetailsVORow,
                   txnsId,
                   headerInterfaceId,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");
    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    // 登録処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;

    }


    // 品目がロット対象である場合
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * 品目ロットトランザクションOIF登録処理    * //
      // ******************************************** //
      retCode = insMtlTransactionLotsIf2(
                  orderDetailsVORow, 
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // 登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }

    retHashMap.put("GroupId", groupId);
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // insOpenIf2

  /***************************************************************************
   * (発注受入入力画面)OIF受入訂正処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param txnsId 取引ID
   * @param groupId グループID
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap correctOpenIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;

    // ************************************** //
    // * 受入トランザクションOIF訂正処理    * //
    // ************************************** //
    retHashMap = correctRcvTransactionsIf(
                   orderDetailsVORow, 
                   receiptDetailsVORow,
                   txnsId,
                   groupId,
                   "0");        // 受入訂正(0)、搬送訂正(1)

    groupId = (Number)retHashMap.get("GroupId");

    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    retCode = (String)retHashMap.get("RetFlag");

    // 登録処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;
      
    }

// 20080513 del yoshimoto Start
/*
    // 品目がロット対象である場合
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * 品目ロットトランザクションOIF訂正処理    * //
      // ******************************************** //
      retCode = correctMtlTransactionLotsIf(
                  orderDetailsVORow, 
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // 登録・訂正処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }

      // ******************************************** //
      // * 受入ロットトランザクションOIF訂正処理    * //
      // ******************************************** //
      retCode = correctRcvLotsIf(
                  orderDetailsVORow,
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // 登録・訂正処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }
*/
// 20080513 del yoshimoto End

    retHashMap.put("GroupId", groupId);

    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // correctOpenIf

  /***************************************************************************
   * (発注受入入力画面)OIF搬送訂正処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param txnsId 取引ID
   * @param groupId グループID
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap correctOpenIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;

    // ************************************** //
    // * 受入トランザクションOIF訂正処理    * //
    // ************************************** //
    retHashMap = correctRcvTransactionsIf(
                   orderDetailsVORow, 
                   receiptDetailsVORow,
                   txnsId,
                   groupId,
                   "1");       // 受入訂正(0)、搬送訂正(1)

    groupId = (Number)retHashMap.get("GroupId");

    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    retCode = (String)retHashMap.get("RetFlag");

    // 登録処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;
      
    }

    // 品目がロット対象である場合
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * 品目ロットトランザクションOIF訂正処理    * //
      // ******************************************** //
      retCode = correctMtlTransactionLotsIf(
                  orderDetailsVORow, 
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // 登録・訂正処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }

      // ******************************************** //
      // * 受入ロットトランザクションOIF訂正処理    * //
      // ******************************************** //
      retCode = correctRcvLotsIf(
                  orderDetailsVORow,
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // 登録・訂正処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }

    retHashMap.put("GroupId", groupId);
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // correctOpenIf

  /***************************************************************************
   * (共通)受入ヘッダOIF登録処理を行うメソッドです。
   * @param row 発注明細
   * @param groupId グループID
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insRcvHeadersIf(
    OARow row,
    Number groupId
  ) throws OAException
  {

    HashMap setParams = new HashMap();


    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注番号
    setParams.put("HeaderNumber", row.getAttribute("HeaderNumber"));
    // 発注ヘッダ.納入日
    setParams.put("DeliveryDate", row.getAttribute("DeliveryDate"));
    // 発注ヘッダ.仕入先ID
    setParams.put("VendorId", row.getAttribute("VendorId"));
    // グループID
    setParams.put("GroupId",  groupId);


    // ************************************ //
    // * 受入ヘッダOIF登録処理            * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvHeadersIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvHeadersIf

  /***************************************************************************
   * (発注受入入力画面)受入トランザクションOIF登録処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param txnsId 取引ID
   * @param headerInterfaceId 受入ヘッダOIF.header_interface_id
   * @param groupId 受入ヘッダOIF.group_id
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap insRcvTransactionsIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number headerInterfaceId,
    Number groupId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // (画面)受入数量数量を取得
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注明細.納入先コード
    setParams.put("LocationCode",       orderDetailsVORow.getAttribute("LocationCode"));
    // 発注明細ID
    setParams.put("LineId",             orderDetailsVORow.getAttribute("LineId"));
    // 受入ヘッダOIFのGROUP_IDと同値を指定
    setParams.put("GroupId",            groupId);
    // 納入日
    setParams.put("TxnsDate",           receiptDetailsVORow.getAttribute("TxnsDate"));
    // 発注明細.品目基準単位
    setParams.put("UnitMeasLookupCode", orderDetailsVORow.getAttribute("UnitMeasLookupCode"));  
    // 発注明細.品目ID(ITEM_ID)
    setParams.put("PlaItemId",          orderDetailsVORow.getAttribute("PlaItemId"));
    // 発注ヘッダ.発注ヘッダID
    setParams.put("HeaderId",           orderDetailsVORow.getAttribute("HeaderId"));
    // 発注ヘッダ.納入日
    setParams.put("DeliveryDate",       orderDetailsVORow.getAttribute("DeliveryDate"));
    // 受入返品実績(アドオン)の取引ID
    setParams.put("TxnsId",             txnsId);
    // 受入ヘッダOIFのINTERFACE_TRANSACTION_ID
    setParams.put("HeaderInterfaceId",  headerInterfaceId);


    // 換算が必要な場合
    if (conversionFlag)
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 受入数量を入数で換算
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {
      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }

    // ************************************ //
    // * 受入トランザクションOIF登録処理  * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvTransactionsIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvTransactionsIf2

  /***************************************************************************
   * (発注受入入力画面)受入トランザクションOIF訂正処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param txnsId 取引ID
   * @param groupId 受入ヘッダOIF.group_id
   * @param processCode 処理区分(0:受入訂正、1:搬送訂正)
   * @return HashMap 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap correctRcvTransactionsIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId,
    String processCode
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // 受入数量を取得
// 20080526 mod yoshimoto Start
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
// 2009-03-11 H.Iida MOD START 本番障害#1270
//    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);
    BigDecimal bRcvRtnQuantity = new BigDecimal(String.valueOf(rcvRtnQuantity));
// 2009-03-11 H.Iida MOD END
// 20080526 mod yoshimoto End

    // 訂正前受入数量を取得
    Number quantity   =(Number)receiptDetailsVORow.getAttribute("Quantity");
// 2009-03-11 H.Iida MOD START 本番障害#1270
//    double dQuantity  = Double.parseDouble(quantity.toString());
    BigDecimal bQuantity = new BigDecimal(String.valueOf(quantity));
// 2009-03-11 H.Iida MOD END
    

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // INパラメータ取得   
    // 発注ヘッダ.発注番号
    setParams.put("HeaderNumber", orderDetailsVORow.getAttribute("HeaderNumber"));
    // 発注ヘッダ.発注ヘッダID
    setParams.put("HeaderId",     orderDetailsVORow.getAttribute("HeaderId"));
    // 発注明細ID
    setParams.put("LineId",       orderDetailsVORow.getAttribute("LineId"));
    // 受入返品実績(アドオン)の取引ID
    setParams.put("TxnsId",       txnsId);
    // グループID
    setParams.put("GroupId",      groupId);
    // ロット対象
    setParams.put("LotCtl",       orderDetailsVORow.getAttribute("LotCtl"));
    // 処理区分
    setParams.put("ProcessCode",  processCode);
// 2008-12-05 H.Itou Add Start 本番障害#481対応
    // 取引日
    setParams.put("TxnsDate",  receiptDetailsVORow.getAttribute("TxnsDate"));
// 2008-12-05 H.Itou Add End

    // 換算が必要な場合
    if (conversionFlag) 
    {
// 2009-03-11 H.Iida MOD START 本番障害#1270
//      double dItemAmount = Double.parseDouble(sItemAmount); // 入数
      BigDecimal bItemAmount = new BigDecimal(String.valueOf(sItemAmount));

      // 受入数量(訂正分)
//      double dSubRcvRtnQuantity = (dRcvRtnQuantity * dItemAmount) - dQuantity;
      BigDecimal bmSubRcvRtnQuantity = bRcvRtnQuantity.multiply(bItemAmount);
      BigDecimal bsSubRcvRtnQuantity = bmSubRcvRtnQuantity.subtract(bQuantity);

      // 受入数量(換算注意)
//      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
      setParams.put("RcvRtnQuantity", bsSubRcvRtnQuantity.toString());
// 2009-03-11 H.Iida MOD END

    // 換算が不要な場合
    } else
    {

// 2009-03-11 H.Iida MOD START 本番障害#1270
      // 受入数量(訂正分)
//      double dSubRcvRtnQuantity = dRcvRtnQuantity - dQuantity;
      BigDecimal bsSubRcvRtnQuantity = bRcvRtnQuantity.subtract(bQuantity);

//      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
      setParams.put("RcvRtnQuantity", bsSubRcvRtnQuantity.toString());
// 2009-03-11 H.Iida MOD END

    }

    // ************************************ //
    // * 受入トランザクションOIF訂正処理  * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.correctRcvTransactionsIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // correctRcvTransactionsIf


  /***************************************************************************
   * (発注受入入力画面)品目ロットトランザクションOIF登録処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param interfaceTransactionId 受入トランザクションOIF.interface_transaction_id
   * @return String 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String insMtlTransactionLotsIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // 受入数量を取得
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注明細.ロットNo
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));
    // 受入ヘッダOIFのINTERFACE_TRANSACTION_ID
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);

    // 換算が必要な場合
    if (conversionFlag)
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 受入数量
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {
      // 受入数量(換算注意)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }


    // ******************************************* //
    // * 品目ロットトランザクションOIF登録処理   * //
    // ******************************************* //
    String retCode = XxpoUtility.insertMtlTransactionLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // insMtlTransactionLotsIf2

  /***************************************************************************
   * (発注受入入力画面)品目ロットトランザクションOIF訂正処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param interfaceTransactionId 受入ヘッダOIF.header_interface_id
   * @return String 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String correctMtlTransactionLotsIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // 訂正前受入数量を取得
    Number quantity   =(Number)receiptDetailsVORow.getAttribute("Quantity");
// 2009-03-11 H.Iida MOD START 本番障害#1270
//    double dQuantity  = Double.parseDouble(quantity.toString());
    BigDecimal bQuantity = new BigDecimal(String.valueOf(quantity));
// 2009-03-11 H.Iida MOD END

    // 受入数量を取得
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
// 2009-03-11 H.Iida MOD START 本番障害#1270
//    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);
    BigDecimal bRcvRtnQuantity = new BigDecimal(String.valueOf(rcvRtnQuantity));
// 2009-03-11 H.Iida MOD END

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注明細.ロットNo
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));
    // InterfaceTransactionId
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);
// 20080611 yoshimoto add Start ST不具合#72
    // 発注明細.OPM品目ID
    setParams.put("OpmItemId",          orderDetailsVORow.getAttribute("OpmItemId"));
// 20080611 yoshimoto add End ST不具合#72

    // 換算が必要な場合
    if (conversionFlag) 
    {

// 2009-03-11 H.Iida MOD START 本番障害#1270
//      double dItemAmount = Double.parseDouble(sItemAmount); // 入数
      BigDecimal bItemAmount = new BigDecimal(String.valueOf(sItemAmount));

      // 受入数量(訂正分)
//      double dSubRcvRtnQuantity = (dRcvRtnQuantity * dItemAmount) - dQuantity;
      BigDecimal bmSubRcvRtnQuantity = bRcvRtnQuantity.multiply(bItemAmount);
      BigDecimal bsSubRcvRtnQuantity = bmSubRcvRtnQuantity.subtract(bQuantity);

      // 受入数量(換算注意)
//      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
      setParams.put("RcvRtnQuantity", bsSubRcvRtnQuantity.toString());

// 2009-03-11 H.Iida MOD END

    // 換算が不要な場合
    } else
    {

// 2009-03-11 H.Iida MOD START 本番障害#1270
      // 受入数量(訂正分)
//      double dSubRcvRtnQuantity = dRcvRtnQuantity - dQuantity;
      BigDecimal bsSubRcvRtnQuantity = bRcvRtnQuantity.subtract(bQuantity);

//      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
      setParams.put("RcvRtnQuantity", bsSubRcvRtnQuantity.toString());

// 2009-03-11 H.Iida MOD END

    }

    // ******************************************* //
    // * 品目ロットトランザクションOIF訂正処理   * //
    // ******************************************* //
    String retCode = XxpoUtility.correctMtlTransactionLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // correctMtlTransactionLotsIf

  /***************************************************************************
   * (発注受入入力画面)受入ロットトランザクションOIF訂正処理を行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @param interfaceTransactionId 受入ヘッダOIF.header_interface_id
   * @return String 登録処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String correctRcvLotsIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 換算入数を取得
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // 訂正前受入数量を取得
    Number quantity   =(Number)receiptDetailsVORow.getAttribute("Quantity");
// 2009-03-11 H.Iida MOD START 本番障害#1270
//    double dQuantity  = Double.parseDouble(quantity.toString());
    BigDecimal bQuantity = new BigDecimal(String.valueOf(quantity));
// 2009-03-11 H.Iida MOD END

    // 受入数量を取得
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
// 2009-03-11 H.Iida MOD START 本番障害#1270
//    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);
    BigDecimal bRcvRtnQuantity = new BigDecimal(String.valueOf(rcvRtnQuantity));
// 2009-03-11 H.Iida MOD END

    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    // 発注明細.ロットNo
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));
    // 発注ヘッダID
    setParams.put("HeaderId",           orderDetailsVORow.getAttribute("HeaderId"));
    // 発注明細ID
    setParams.put("LineId",             orderDetailsVORow.getAttribute("LineId"));
    // 取引ID
    setParams.put("TxnsId",             receiptDetailsVORow.getAttribute("TxnsId"));
    // InterfaceTransactionId
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);
// 20080611 yoshimoto add Start ST不具合#72
    // 発注明細.OPM品目ID
    setParams.put("OpmItemId",          orderDetailsVORow.getAttribute("OpmItemId"));
// 20080611 yoshimoto add End ST不具合#72

    // 換算が必要な場合
    if (conversionFlag) 
    {
// 2009-03-11 H.Iida MOD START 本番障害#1270
//      double dItemAmount = Double.parseDouble(sItemAmount); // 入数
      BigDecimal bItemAmount = new BigDecimal(String.valueOf(sItemAmount));

      // 受入数量(訂正分)
//      double dSubRcvRtnQuantity = (dRcvRtnQuantity * dItemAmount) - dQuantity;
      BigDecimal bmSubRcvRtnQuantity = bRcvRtnQuantity.multiply(bItemAmount);
      BigDecimal bsSubRcvRtnQuantity = bmSubRcvRtnQuantity.subtract(bQuantity);

      // 受入数量(換算注意)
//      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
      setParams.put("RcvRtnQuantity", bsSubRcvRtnQuantity.toString());
// 2009-03-11 H.Iida MOD END

    // 換算が不要な場合
    } else
    {
// 2009-03-11 H.Iida MOD START 本番障害#1270
      // 受入数量(訂正分)
//      double dSubRcvRtnQuantity = dRcvRtnQuantity - dQuantity;
      BigDecimal bsSubRcvRtnQuantity = bRcvRtnQuantity.subtract(bQuantity);

//      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
      setParams.put("RcvRtnQuantity", bsSubRcvRtnQuantity.toString());
// 2009-03-11 H.Iida MOD END
    }


    // ******************************************* //
    // * 受入ロットトランザクションOIF訂正処理   * //
    // ******************************************* //
    String retCode = XxpoUtility.correctRcvLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // correctRcvLotsIf

  /***************************************************************************
   * (発注受入入力画面)OPMロットMST更新処理を行うメソッドです。
   * @return String 更新処理結果
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String updIcLotsMstTxns2()
  throws OAException
  {

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 受入明細VOを取得
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // ロットNoを取得
    String lotNo     = (String)orderDetailsVORow.getAttribute("LotNo");
    // OPM品目IDを取得
    Number opmItemId = (Number)orderDetailsVORow.getAttribute("OpmItemId");
    // OPMロットMST最終更新日を取得
    String lotLastUpdateDate   = (String)orderDetailsVORow.getAttribute("LotLastUpdateDate");
    // OPMロットMST.納入日(初回)
    Date firstTimeDeliveryDate = (Date)orderDetailsVORow.getAttribute("FirstTimeDeliveryDate");
    // OPMロットMST.納入日(最終)
    Date finalDeliveryDate     = (Date)orderDetailsVORow.getAttribute("FinalDeliveryDate");

    HashMap setParams = new HashMap();

    // ************************************************** //
    // * 受入明細(納入日の)最小日付と最大日付を取得     * //
    // ************************************************** //
    Date minTxnsDate = null; 
    Date maxTxnsDate = null;

    receiptDetailsVO.first();

    // 明細画取得できる間、処理を継続して、(納入日の)最小日付と最大日付を取
    while (receiptDetailsVO.getCurrentRow() != null) 
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      Date txnsDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");

      // 初期化
      if (XxcmnUtility.isBlankOrNull(minTxnsDate))
      {
        minTxnsDate = txnsDate;
      }
      if (XxcmnUtility.isBlankOrNull(maxTxnsDate))
      {
        maxTxnsDate = txnsDate;
      }
      
      // 最小日付と比較
      if (XxcmnUtility.chkCompareDate(1, minTxnsDate, txnsDate))
      {
        minTxnsDate = txnsDate;
      }

      // 最大日付と比較
      if (XxcmnUtility.chkCompareDate(1, txnsDate, maxTxnsDate))
      {
        maxTxnsDate = txnsDate;
      }

      receiptDetailsVO.next();

    }


    // ************************************ //
    // * パラメータを設定                 * //
    // ************************************ //
    setParams.put("LotNo", lotNo);
    setParams.put("ItemId", opmItemId);

    // OPMロットMST.納入日(初回)がブランク(Null)である、
    //   または、画面.受入明細.納入日がOPMロットMST.納入日(初回)より過去日の場合
    if (XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, firstTimeDeliveryDate, minTxnsDate))
    {
// 2009-01-16 v1.9 T.Yoshimoto Mod Start 本番#1006
      //setParams.put("FirstTimeDeliveryDate", minTxnsDate.toString());    // 納入日(初回)
      setParams.put("FirstTimeDeliveryDate", XxcmnUtility.stringValue(minTxnsDate));    // 納入日(初回)
// 2009-01-16 v1.9 T.Yoshimoto Mod End 本番#1006
    }

    // OPMロットMST.納入日(最終)がブランク(Null)である、
    //   または、画面.受入明細.納入日がOPMロットMST.納入日(最終)より未来日の場合
    if (XxcmnUtility.isBlankOrNull(finalDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, maxTxnsDate, finalDeliveryDate))
    {
// 2009-01-16 v1.9 T.Yoshimoto Mod Start #1006
      //setParams.put("FinalDeliveryDate", maxTxnsDate.toString());       // 納入日(最終)
      setParams.put("FinalDeliveryDate", XxcmnUtility.stringValue(maxTxnsDate));       // 納入日(最終)
// 2009-01-16 v1.9 T.Yoshimoto Mod End #1006
    }

    // ロック取得処理
    getOpmLotMstRowLock(lotNo,       // ロットNo
                        opmItemId);  // OPM品目ID

    // 排他制御
    chkOpmLotMstExclusiveControl(lotNo,               // ロットNo
                                 opmItemId,           // OPM品目ID
                                 lotLastUpdateDate);  // 最終更新日

    // ****************** //
    // * 更新処理       * //
    // ****************** //
    XxpoUtility.updateIcLotsMstTxns2(
      getOADBTransaction(),
      setParams);

    return XxcmnConstants.RETURN_SUCCESS;

  } // updIcLotsMstTxns2

  /***************************************************************************
   * (発注受入入力画面)在庫数量API起動処理を行うメソッドです。
   * @param sw 0:初回登録処理、1:訂正処理
   * @param txnsId 取引ID
   * @param receiptDetailsVORow 受入明細
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void insIcTranCmp2(
    String sw,
    Number txnsId,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    setParams.put("LocationCode",       orderDetailsVORow.getAttribute("VendorStockWhse"));    // 保管場所(相手先在庫入庫先)
    setParams.put("ItemNo",             orderDetailsVORow.getAttribute("OpmItemNo"));          // 品目(OPM品目名)
    setParams.put("UnitMeasLookupCode", orderDetailsVORow.getAttribute("UnitMeasLookupCode")); // 品目基準単位
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));              // ロット
    setParams.put("TxnsDate",           receiptDetailsVORow.getAttribute("TxnsDate"));         // 取引日(受入明細.納入日)
    setParams.put("ReasonCode",         XxpoConstants.CTPTY_INV_SHIP_RSN);                     // 事由コード(XXPO_CTPTY_INV_SHIP_RSN)
    setParams.put("TxnsId",             txnsId);                                               // 文書ソースID(受入返品実績(アドオン).取引ID)

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 受入数量を取得
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // 訂正前受入数量を取得
    Number quantity = (Number)receiptDetailsVORow.getAttribute("Quantity");


    // 換算が必要な場合
    if (conversionFlag)
    {
      // 換算入数を取得
      String sItemAmount = XxcmnUtility.commaRemoval(
                             (String)orderDetailsVORow.getAttribute("ItemAmount"));
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 受入数量
      // 初回受入時
      if (XxcmnConstants.STRING_ZERO.equals(sw))
      {

        // 受入数量 * 入数 * (-1)
        dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount * (-1);

      // 訂正処理時
      } else
      {

        // ((訂正後の受入数量 * 入数) - 訂正前の受入数量) * (-1)
        dRcvRtnQuantity = ((dRcvRtnQuantity * dItemAmount) - quantity.doubleValue()) * (-1);

      }

      // 受入数量(換算注意)
      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    // 換算が不要な場合
    } else
    {
      // 初回受入時
      if (XxcmnConstants.STRING_ZERO.equals(sw))
      {

        // 受入数量 * (-1)
        dRcvRtnQuantity = dRcvRtnQuantity * (-1);

      // 訂正処理時
      } else
      {

        // (訂正後の受入数量 - 訂正前の受入数量) * (-1)
        dRcvRtnQuantity = (dRcvRtnQuantity - quantity.doubleValue()) * (-1);

      }

      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    }

    // 在庫数量APIを起動
    XxpoUtility.insertIcTranCmp(
      getOADBTransaction(),
      setParams);

  } // insIcTranCmp2

  /***************************************************************************
   * (発注受入入力画面)発注ヘッダ.ステータス変更を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chgStatus2()
  throws OAException
  {
    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // 現在のステータスコードを取得
    String statusCode = (String)orderDetailsVORow.getAttribute("StatusCode");
    // 発注ヘッダIDを取得
    Number headerId = (Number)orderDetailsVORow.getAttribute("HeaderId");

    // 発注ヘッダに紐付く全ての発注明細の数量確定フラグが'Y'であるかを確認
    String chkAllFinDecisionAmountFlg = XxpoUtility.chkAllFinDecisionAmountFlg(
                                          getOADBTransaction(),
                                          headerId);

    // 発注ヘッダに紐付く全ての発注明細の数量確定フラグが'Y'の場合
    if (XxcmnConstants.STRING_Y.equals(chkAllFinDecisionAmountFlg))
    {

      // ロック取得処理
      getHeaderRowLock(headerId);

      // 排他制御
      chkHdrExclusiveControl(
        headerId,
        (String)orderDetailsVORow.getAttribute("PhaLastUpdateDate"));

      // 更新処理(ステータスコード：数量確定済(20))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_FINISH_DECISION_AMOUNT,  // 数量確定済(20)
        headerId);                                    // 発注ヘッダID

    // 現在のステータスが、発注作成済(20)の場合  
    } else if (XxpoConstants.STATUS_FINISH_ORDERING_MAKING.equals(statusCode)) 
    {

      // ロック取得処理
      getHeaderRowLock(headerId);

      // 排他制御    
      chkHdrExclusiveControl(
        headerId,
        (String)orderDetailsVORow.getAttribute("PhaLastUpdateDate"));

      // 更新処理(ステータスコード：受入あり(15))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_REPUTATION_CASE, // 受入あり(15)
        headerId);                            // 発注ヘッダID

    }

  } // chgStatus2

  /***************************************************************************
   * (発注受入入力画面)トークン用の情報を取得するメソッドです。
   * @param sw 0:受入後倒し/受入減数計上、1:受入増数計上
   * @return HashMap トークン
   * @throws OAException OA例外
   ***************************************************************************
   */
  public HashMap getToken2(String sw) throws OAException
  {
    // トークンを格納
    HashMap tokens = new HashMap();

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow     = (OARow)orderDetailsVO.first();

    // 受入後倒し/受入減数計上
    if (XxcmnConstants.STRING_ZERO.equals(sw))
    {
      // 納入先名
      tokens.put(XxcmnConstants.TOKEN_LOCATION, (String)orderDetailsVORow.getAttribute("LocationName"));

    // 受入増数計上
    } else
    {
      // 相手先在庫入庫先名
      tokens.put(XxcmnConstants.TOKEN_LOCATION, (String)orderDetailsVORow.getAttribute("VendorStockWhseName"));
    }

    // 品目名
    tokens.put(XxcmnConstants.TOKEN_ITEM,     (String)orderDetailsVORow.getAttribute("OpmItemName"));
    // ロットNo
    tokens.put(XxcmnConstants.TOKEN_LOT,      (String)orderDetailsVORow.getAttribute("LotNo"));

    return tokens;
  } // getToken2

  /***************************************************************************
   * (発注受入入力画面)新規行フラグを変更するメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chgNewRowFlag()
  throws OAException
  {
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    Row[] rows = receiptDetailsVO.getFilteredRows("NewRowFlag", Boolean.TRUE);

    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      row.setAttribute("NewRowFlag", Boolean.FALSE);
    }
  }

  /***************************************************************************
   * (共通)発注ヘッダのロック処理を行うメソッドです。
   * @param headerId 発注ヘッダID
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getHeaderRowLock(
    Number headerId
  ) throws OAException
  {

    String apiName = "getHeaderRowLock";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pha_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pha.po_header_id header_id "); // ヘッダーID
    sb.append("    FROM   po_headers_all pha ");         // 発注ヘッダ
    sb.append("    WHERE  pha.po_header_id = :1 ");
    sb.append("    FOR UPDATE OF pha.po_header_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  pha_cur; ");
    sb.append("  CLOSE pha_cur; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQLを実行します
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(headerId));

      cstmt.execute();

    } catch (SQLException s)
    {

      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // ロックエラー
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);
    } finally
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {

        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getHeaderRowLock

  /***************************************************************************
   * (共通)発注ヘッダーの排他制御チェックを行うメソッドです。
   * @param headerId 発注ヘッダID
   * @param lastUpdateDate 最終更新日
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkHdrExclusiveControl(
    Number headerId,
    String lastUpdateDate
  ) throws OAException
  {

    String apiName  = "chkHdrExclusiveControl";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pha.po_header_id) cnt "); // 発注ヘッダID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   po_headers_all pha ");          // 発注ヘッダ
      sb.append("  WHERE  pha.po_header_id = :2 ");       // 発注ヘッダID
      sb.append("  AND    TO_CHAR(pha.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(headerId));
      cstmt.setString(i++, lastUpdateDate);

      cstmt.execute();

      // 排他エラーの場合
      if (cstmt.getInt(1) == 0)
      {

        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s) 
    {

      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkHdrExclusiveControl

  /***************************************************************************
   * (共通)発注明細のロック処理を行うメソッドです。
   * @param lineId 発注明細ID
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getDetailsRowLock(
    Number lineId
  ) throws OAException 
  {

    String apiName = "getDetailsRowLock";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pla_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pla.po_line_id line_id ");     // ヘッダーID
    sb.append("    FROM   po_lines_all pla ");           // 発注明細
    sb.append("    WHERE  pla.po_line_id = :1 ");
    sb.append("    FOR UPDATE OF pla.po_line_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  pla_cur; ");
    sb.append("  CLOSE pla_cur; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQLを実行します
      cstmt.setInt(1, XxcmnUtility.intValue(lineId));

      cstmt.execute();

    } catch (SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ロックエラー
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getDetailsRowLock

  /***************************************************************************
   * (共通)発注明細の排他制御チェックを行うメソッドです。
   * @param lineId 発注明細ID
   * @param lastUpdateDate 最終更新日
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkDetailsExclusiveControl(
    Number lineId,
    String lastUpdateDate
  ) throws OAException
  {

    String apiName  = "chkDetailsExclusiveControl";

    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pla.po_line_id) cnt ");              // 発注ヘッダID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   po_lines_all pla ");                       // 発注明細
      sb.append("  WHERE  pla.po_line_id = TO_NUMBER(:2) ");         // 明細行ID
      sb.append("  AND    TO_CHAR(pla.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);


      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(lineId));
      cstmt.setString(i++, lastUpdateDate);

      cstmt.execute();

      // 排他エラーの場合
      if (cstmt.getInt(1) == 0)
      {

        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s)
    {

      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkDetailsExclusiveControl


  /***************************************************************************
   * (共通)OPMロットMSTのロック処理を行うメソッドです。
   * @param lotNo ロットNo
   * @param itemId OPM品目ID
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getOpmLotMstRowLock(
    String lotNo,
    Number itemId
  ) throws OAException 
  {

    String apiName = "getOpmLotMstRowLock";
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR lotMst_cur ");
    sb.append("  IS ");
    sb.append("    SELECT ilm.lot_id lot_id ");    // ロットID
    sb.append("    FROM   IC_LOTS_MST ilm ");      // OPMロットMST
    sb.append("    WHERE  ilm.LOT_NO  = :1 ");
    sb.append("    AND    ilm.ITEM_ID = :2 ");
    sb.append("    FOR UPDATE OF ilm.lot_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  lotMst_cur; ");
    sb.append("  CLOSE lotMst_cur; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQLを実行します
      int i = 1;
      cstmt.setString(i++, lotNo);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));

      cstmt.execute();

    } catch (SQLException s)
    {
      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ロックエラー
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10138);
    } finally
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getOpmLotMstRowLock

  /***************************************************************************
   * (共通)OPMロットMST排他制御チェックを行うメソッドです。
   * @param lotNum ロットNo
   * @param itemId OPM品目ID
   * @param lotLastUpdateDate 最終更新日
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkOpmLotMstExclusiveControl(
    String lotNum,
    Number itemId,
    String lotLastUpdateDate
  ) throws OAException
  {
    String apiName  = "chkOpmLotMstExclusiveControl";

    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(ilm.lot_id) cnt ");       // 品目ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   IC_LOTS_MST ilm ");             // OPMロットマスタ
      sb.append("  WHERE  ilm.item_id = :2 ");            // 品目ID
      sb.append("  AND    ilm.LOT_NO  = :3 ");            // ロットNo
      sb.append("  AND    TO_CHAR(ilm.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 "); // 最終更新日
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setString(i++, lotNum);
      cstmt.setString(i++, lotLastUpdateDate);

      cstmt.execute();

      // 排他エラーの場合
      if (cstmt.getInt(1) == 0)
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s)
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        if (cstmt != null)
        {
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkOpmLotMstExclusiveControl

  /***************************************************************************
   * (共通)受入返品(アドオン)のロック処理を行うメソッドです。
   * @param txnsId 取引ID
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getRcvRtnRowLock(
    Number txnsId
  ) throws OAException 
  {

    String apiName = "getRcvRtnRowLock";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR rart_cur ");
    sb.append("  IS ");
    sb.append("    SELECT rart.txns_id txns_id ");       // 取引ID
    sb.append("    FROM   xxpo_rcv_and_rtn_txns rart "); // 受入返品実績(アドオン)
    sb.append("    WHERE  rart.txns_id = :1 ");
    sb.append("    FOR UPDATE OF rart.txns_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  rart_cur; ");
    sb.append("  CLOSE rart_cur; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {

      //PL/SQLを実行します
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(txnsId));

      cstmt.execute();

    } catch (SQLException s)
    {

      // ロールバック
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ロックエラー
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);
    } finally
    {
      try
      {
        if (cstmt != null)
        {
          cstmt.close();
        }
      } catch (SQLException s)
      {
        // ロールバック
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getRcvAndRtnTxnsRowLock

  /***************************************************************************
   * (共通)受入返品実績(アドオン)の排他制御チェックを行うメソッドです。
   * @param txnsId 取引ID
   * @param lastUpdateDate 最終更新日
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkRcvRtnExclusiveControl(
    Number txnsId,
    String lastUpdateDate
  )throws OAException 
  {

    String apiName  = "chkRcvRtnExclusiveControl";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(rart.txns_id) cnt ");     // 取引ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   xxpo_rcv_and_rtn_txns rart ");  // 受入返品実績(アドオン)
      sb.append("  WHERE  rart.txns_id = :2 ");           // 取引ID
      sb.append("  AND    TO_CHAR(rart.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(txnsId));
      cstmt.setString(i++, lastUpdateDate);

      cstmt.execute();

      // 排他エラーの場合
      if (cstmt.getInt(1) == 0)
      {

        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s)
    {

      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        if (cstmt != null)
        {
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkRcvRtnExclusiveControl

  /***************************************************************************
   * (共通)OIF更新有無チェックを行うメソッドです。
   * @param orderDetailsVORow 発注明細
   * @param receiptDetailsVORow 受入明細
   * @return String 1:増数訂正による更新必要、0:更新不要、-1:減数訂正による更新必要
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String chkSubRcvRtnQuantity(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    // ************************************ //
    // * 換算有無チェック                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // 換算有無チェックを実施
    conversionFlag = chkConversion(
                       prodClassCode,  // 商品区分
                       itemClassCode,  // 品目区分
                       convUnit);      // 入出庫換算単位

    // 受入数量を取得
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);
    // 訂正前受入数量を取得
    Number quantity  = (Number)receiptDetailsVORow.getAttribute("Quantity");
    double dQuantity = XxcmnUtility.doubleValue(quantity);


    // 換算が必要な場合
    if (conversionFlag)
    {
      // 換算入数を取得
      String sItemAmount = XxcmnUtility.commaRemoval(
                             (String)orderDetailsVORow.getAttribute("ItemAmount"));
      double dItemAmount = Double.parseDouble(sItemAmount); // 入数

      // 受入数量 * 入数
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

    }

    if (dQuantity == dRcvRtnQuantity)
    {

      return "0";

    } else if (dQuantity > dRcvRtnQuantity)
    {

      return "-1";

    } else
    {
    
      return "1";
      
    }

  } // chkSubRcvRtnQuantity

  /***************************************************************************
   * (共通)摘要更新有無チェックを行うメソッドです。
   * @param receiptDetailsVORow 受入明細
   * @return true:更新必要、false:更新不要
   * @throws OAException OA例外
   ***************************************************************************
   */
  public boolean chkUpdLineDescription(
    OARow receiptDetailsVORow
  ) throws OAException
  {

    // 更新前摘要を取得
    String baseLineDescription = (String)receiptDetailsVORow.getAttribute("BaseLineDescription");

    // 画面.摘要を取得
    String lineDescription = (String)receiptDetailsVORow.getAttribute("LineDescription");

    // 両項目ともブランクの場合は、更新不要
    if (XxcmnUtility.isBlankOrNull(baseLineDescription)
      && XxcmnUtility.isBlankOrNull(lineDescription))
    {
      return false;
    }

    // 片方のみブランクの場合は、更新必要
    if (!XxcmnUtility.isBlankOrNull(baseLineDescription)
      && XxcmnUtility.isBlankOrNull(lineDescription))
    {
      return true;
    }

    if (XxcmnUtility.isBlankOrNull(baseLineDescription)
      && !XxcmnUtility.isBlankOrNull(lineDescription))
    {
      return true;
    }

    // 両方入力済みである場合は、比較
    if (!baseLineDescription.equals(lineDescription))
    {
      return true;
    }

    return false;

  } // chkUpdLineDescription

  /***************************************************************************
   * (共通)換算有無チェックを行うメソッドです。
   * @param prodClassCode 商品区分
   * @param itemClassCode 品目区分
   * @param convUnit 入出庫換算単位
   * @return true:換算必要、false:換算不要
   * @throws OAException OA例外
   ***************************************************************************
   */
  public boolean chkConversion(
    String prodClassCode,
    String itemClassCode,
    String convUnit
  ) throws OAException
  {

    // 商品区分2(ドリンク)かつ、品目区分5(製品)かつ、入出庫換算単位がブランク以外の場合
    if ((XxpoConstants.PROD_CLASS_DRINK.equals(prodClassCode))
      && (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
      && !(XxcmnUtility.isBlankOrNull(convUnit)))
    {

      // 換算が必要
      return true;

    }

    // 換算は不要
    return false;

  } // chkConversion

  /***************************************************************************
   * (共通)コミット処理を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doCommit() throws OAException
  {
    // コミット
    getOADBTransaction().commit();
  } // doCommit

  /***************************************************************************
   * (共通)ロールバック処理を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doRollBack() throws OAException
  {

    // ロールバック処理
    XxpoUtility.rollBack(getOADBTransaction());
    
  } // doRollBack

  /***************************************************************************
   * (共通)行挿入処理を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void addRow() throws OAException
  {

    // 発注明細VOを取得
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();

    // 受入情報VOを取得
    OAViewObject receiptDetailsVO  = getXxpoReceiptDetailsVO1();
    OARow createRow  = (OARow)receiptDetailsVO.createRow();

    // 最新明細番号を設定
    int newRcvRtnLineNumber = receiptDetailsVO.getRowCount() + 1;
    createRow.setAttribute("RcvRtnLineNumber", new Number(newRcvRtnLineNumber));

    // 初回受入(受入返品実績(アドオン)未登録)の場合
    if (receiptDetailsVO.getRowCount() == 0)
    {
      // 発注明細.発注単位を設定
      OARow orderDetailsVORow = (OARow)orderDetailsVO.first();
      String unitName         = (String)orderDetailsVORow.getAttribute("UnitName");

      createRow.setAttribute("RcvRtnUom", unitName);
// 2008-11-05 H.Itou Add Start 統合テスト指摘71
      // 初回の場合、発注明細の納入日、数量を初期表示する。
      createRow.setAttribute("TxnsDate",       (Date)orderDetailsVORow.getAttribute("DeliveryDate"));
      createRow.setAttribute("RcvRtnQuantity", (String)orderDetailsVORow.getAttribute("OrderAmount"));
// 2008-11-05 H.Itou Add End


    // 1行以上の明細が存在する場合
    } else
    {

      OARow receiptDetailsVORow = (OARow)receiptDetailsVO.first();
      String uom = (String)receiptDetailsVORow.getAttribute("RcvRtnUom");

      // 初回以降の受入(受入返品実績(アドオン)登録済)の場合
      if (!XxcmnUtility.isBlankOrNull(uom)) 
      {
        // 受入返品実績(アドオン).受入返品単位を設定
        createRow.setAttribute("RcvRtnUom", uom);

      } else
      {
        // 発注明細.発注単位を設定
        OARow orderDetailsVORow  = (OARow)orderDetailsVO.first();
        String unitName          = (String)orderDetailsVORow.getAttribute("UnitName");

        createRow.setAttribute("RcvRtnUom", unitName);

      }

    }


    // 発注明細.新規作成レコードフラグを初期化(新規:TRUE)
    createRow.setAttribute("NewRowFlag", Boolean.TRUE);
    // 発注明細.受入数量/摘要disableフラグを初期化(新規:FALSE)
    createRow.setAttribute("ReceiptDetailsReadOnly", Boolean.FALSE);


    receiptDetailsVO.last();
    receiptDetailsVO.next();
    receiptDetailsVO.insertRow(createRow);
    createRow.setNewRowState(Row.STATUS_INITIALIZED);

  } // addRow

  /***************************************************************************
   * (共通)行削除処理を行うメソッドです。
   * @return String 残レコード数
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String deleteRow() throws OAException
  {

    // 最終データ入力行番号
    Object lastInputLineNumber = null;

    // 受入情報VO
    OAViewObject receiptDetailsVO  = getXxpoReceiptDetailsVO1();
    OARow currentRow   = null;  // 現在行
    OARow lastInputRow = null;  // 最終データ入力行

    // ************************************ //
    // * 最終データ入力行判別処理         * //
    // ************************************ //
    receiptDetailsVO.first();
    
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      currentRow = (OARow)receiptDetailsVO.getCurrentRow();

      Object txnsDate       = currentRow.getAttribute("TxnsDate");
      Object rcvRtnQuantity = currentRow.getAttribute("RcvRtnQuantity");

      // 納入日または、受入数量の項目にデータが設定されているの場合
      if(!(XxcmnUtility.isBlankOrNull(txnsDate))
        || !(XxcmnUtility.isBlankOrNull(rcvRtnQuantity)))
      {

        // 最終データ入力行を退避
        lastInputRow = currentRow;

      }

      receiptDetailsVO.next();

    }


    // ********************************************** //
    // * 最終データ入力行以降の行の削除処理         * //
    // ********************************************** //
    // 全ての受入明細行においてデータ未入力の場合、全行削除
    if (XxcmnUtility.isBlankOrNull(lastInputRow))
    {
      receiptDetailsVO.first();

      while (receiptDetailsVO.getCurrentRow() != null)
      {
        currentRow = (OARow)receiptDetailsVO.getCurrentRow();

        currentRow.remove();

        receiptDetailsVO.next();

      }
      
    } else 
    {
      // 最終データ入力行番号を取得
      lastInputLineNumber = lastInputRow.getAttribute("RcvRtnLineNumber");

      receiptDetailsVO.first();
    
      while (receiptDetailsVO.getCurrentRow() != null)
      {
        currentRow = (OARow)receiptDetailsVO.getCurrentRow();

        Object currentLineNumber = currentRow.getAttribute("RcvRtnLineNumber");

        // 最終データ入力行番号より、現在行の行番号が大きい場合は、削除処理
        if(XxcmnUtility.chkCompareNumeric(1, currentLineNumber.toString(), lastInputLineNumber.toString()))
        {
          // 空行削除
          currentRow.remove();

        }

        receiptDetailsVO.next();

      }
      
    }

    // 空行削除処理後のレコード数をチェック
    int rowCount = receiptDetailsVO.getRowCount();

    return new Integer(rowCount).toString();

  } // deleteRow

  /***************************************************************************
   * (共通)ユーザー情報を取得するメソッドです。
   * @param row 情報設定VO行
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getUserData(
    OARow row
  ) throws OAException
  {
    // ユーザー情報取得 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // トランザクション
                          );

/*
    // 発注受入検索VO取得
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();

    // 1行目を取得
    OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();
*/

    // 従業員区分をセット
    row.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // 従業員区分

    // 従業員区分が2:外部の場合、仕入先情報をセット
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      row.setAttribute("OutSideUsrVendorCode", retHashMap.get("VendorCode"));  // 仕入先コード
      row.setAttribute("OutSideUsrVendorId",   retHashMap.get("VendorId"));    // 取引先ID
      row.setAttribute("OutSideUsrVendorName", retHashMap.get("VendorName"));  // 取引先ID
      row.setAttribute("OutPurchaseSiteCode",  retHashMap.get("FactoryCode")); // 仕入先サイトコード

    }
  } //getUserData

  /**
   * 
   * Container's getter for XxpoOrderReceiptMakePVO1
   */
  public OAViewObjectImpl getXxpoOrderReceiptMakePVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxpoOrderReceiptMakePVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderDetailsVO1
   */
  public XxpoOrderDetailsVOImpl getXxpoOrderDetailsVO1()
  {
    return (XxpoOrderDetailsVOImpl)findViewObject("XxpoOrderDetailsVO1");
  }


  /**
   * 
   * Container's getter for XxpoOrderReceiptSerchVO1
   */
  public OAViewObjectImpl getXxpoOrderReceiptSerchVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxpoOrderReceiptSerchVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderReceiptVO1
   */
  public XxpoOrderReceiptVOImpl getXxpoOrderReceiptVO1()
  {
    return (XxpoOrderReceiptVOImpl)findViewObject("XxpoOrderReceiptVO1");
  }

  /**
   * 
   * Container's getter for StatusCode2VO1
   */
  public OAViewObjectImpl getStatusCode2VO1()
  {
    return (OAViewObjectImpl)findViewObject("StatusCode2VO1");
  }


  /**
   * 
   * Container's getter for XxpoOrderHeaderVO1
   */
  public XxpoOrderHeaderVOImpl getXxpoOrderHeaderVO1()
  {
    return (XxpoOrderHeaderVOImpl)findViewObject("XxpoOrderHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderDetailTotalVO1
   */
  public XxpoOrderDetailTotalVOImpl getXxpoOrderDetailTotalVO1()
  {
    return (XxpoOrderDetailTotalVOImpl)findViewObject("XxpoOrderDetailTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderReceiptDetailsPVO1
   */
  public XxpoOrderReceiptDetailsPVOImpl getXxpoOrderReceiptDetailsPVO1()
  {
    return (XxpoOrderReceiptDetailsPVOImpl)findViewObject("XxpoOrderReceiptDetailsPVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderDetailsTabVO1
   */
  public XxpoOrderDetailsTabVOImpl getXxpoOrderDetailsTabVO1()
  {
    return (XxpoOrderDetailsTabVOImpl)findViewObject("XxpoOrderDetailsTabVO1");
  }

  /**
   * 
   * Container's getter for XxpoReceiptDetailsVO1
   */
  public XxpoReceiptDetailsVOImpl getXxpoReceiptDetailsVO1()
  {
    return (XxpoReceiptDetailsVOImpl)findViewObject("XxpoReceiptDetailsVO1");
  }

  /**
   * 
   * Container's getter for ApprovedReqCodeVO1
   */
  public OAViewObjectImpl getApprovedReqCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("ApprovedReqCodeVO1");
  }

  /**
   * 
   * Container's getter for DropShipCodeVO1
   */
  public OAViewObjectImpl getDropShipCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("DropShipCodeVO1");
  }

  /**
   * 
   * Container's getter for ApprovedCodeVO1
   */
  public OAViewObjectImpl getApprovedCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("ApprovedCodeVO1");
  }


}
