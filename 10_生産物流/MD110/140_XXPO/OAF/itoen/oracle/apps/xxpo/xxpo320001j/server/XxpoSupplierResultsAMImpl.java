/*============================================================================
* ファイル名 : XxpoSupplierResultsAMImpl
* 概要説明   : 仕入先出荷実績入力:検索アプリケーションモジュール
* バージョン : 1.7
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-06 1.0  吉元強樹     新規作成
* 2008-05-02 1.0  吉元強樹     変更要求対応(#12,36,90)、内部変更要求対応(#28,41)
* 2008-05-21 1.0  吉元強樹     不具合ログ#320_3
* 2008-06-26 1.1  北寒寺正夫   ST不具合#17/結合指摘No3
* 2008-07-11 1.2  伊藤ひとみ   内部変更#153 納入日の未来日チェック追加
* 2008-10-22 1.3  吉元強樹     T_S_599対応
* 2008-11-04 1.4  二瓶大輔     統合障害#51,103、104対応
* 2008-12-06 1.5  伊藤ひとみ   本番障害#528対応
* 2008-12-16 1.6  吉元強樹     本番障害#689,753対応
* 2011-06-01 1.7  窪和重       本番障害#1786対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

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
 * 仕入先出荷実績入力:検索アプリケーションモジュールです。
 * @author  SCS 吉元 強樹
 * @version 1.4
 ***************************************************************************
 */
public class XxpoSupplierResultsAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo320001j.server", "XxpoSupplierResultsAMLocal");
  }

  /**
   * 
   * Container's getter for StatusCodeVO1
   */
  public OAViewObjectImpl getStatusCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("StatusCodeVO1");
  }

  /***************************************************************************
   * (検索画面)初期化処理を行うメソッドです。
   ***************************************************************************
   */
  public void initialize()
  {
    // *********************************** //
    // * 仕入先出荷実績:検索VO 空行取得  * //
    // *********************************** //
    OAViewObject resultsSearchVo = getXxpoResultsSearchVO1();

    // 1行もない場合、空行作成
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1行目を取得
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      // キーに値をセット
      resultsSearchRow.setNewRowState(Row.STATUS_INITIALIZED);
      resultsSearchRow.setAttribute("RowKey", new Number(1));
    }
       
    // ******************************* //
    // *     ユーザー情報取得        * //
    // ******************************* //
    getUserData();

  }

  /***************************************************************************
   * (検索画面)ユーザー情報を取得するメソッドです。
   ***************************************************************************
   */
  public void getUserData()
  {
    // ユーザー情報取得 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // トランザクション
                          );

    // 仕入先出荷実績VO取得
    OAViewObject resultsSearchVo = getXxpoResultsSearchVO1();
    // 1行目を取得
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();
    // 従業員区分をセット
    resultsSearchRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // 従業員区分
    // 従業員区分が2:外部の場合、仕入先情報をセット
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      resultsSearchRow.setAttribute("OutSideUsrVendorCode",  retHashMap.get("VendorCode"));  // 取引先コード
      resultsSearchRow.setAttribute("OutSideUsrVendorId",    retHashMap.get("VendorId"));    // 取引先ID
      resultsSearchRow.setAttribute("OutSideUsrVendorName",  retHashMap.get("VendorName"));  // 取引先ID
      resultsSearchRow.setAttribute("OutSideUsrFactoryCode", retHashMap.get("FactoryCode")); // 工場コード

    }
  }

  /***************************************************************************
   * (検索画面)検索処理を行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  )
  {
    
    // 外部ユーザ識別フラグ取得
    XxpoResultsSearchVOImpl xxpoResultsSearchVo = getXxpoResultsSearchVO1();
    xxpoResultsSearchVo.first();
    String peopleCode = (String)xxpoResultsSearchVo.getCurrentRow().getAttribute("PeopleCode");
    searchParams.put("PeopleCode", peopleCode);

    // 従業員区分が2:外部の場合、自取引IDを設定
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      searchParams.put("OutSideUsrVendorCode", xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrVendorCode"));
      searchParams.put("OutSideUsrVendorId",   xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrVendorId"));
      searchParams.put("OutSideUsrVendorName", xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrVendorName"));
      searchParams.put("OutSideUsrFactoryCode", xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrFactoryCode"));
    }
    
    // 仕入先出荷実績情報VO取得
    XxpoSupplierResultsVOImpl xxpoSupplierResultsVo = getXxpoSupplierResultsVO1();
    // 検索
    xxpoSupplierResultsVo.initQuery(
      searchParams);          // 検索パラメータ用HashMap
     
    // 1行目を取得
    OARow row = (OARow)xxpoSupplierResultsVo.first();
  }

  /***************************************************************************
   * (検索画面)必須チェックを行うメソッドです。
   ***************************************************************************
   */
  public void doRequiredCheck()
  {

    // 仕入先出荷実績:検索項目VO取得
    OAViewObject poResultsSearchVo = getXxpoResultsSearchVO1();
    // 1行目を取得
    OARow poResultsSearchRow = (OARow)poResultsSearchVo.first();

    Object fdDate  = poResultsSearchRow.getAttribute("DeliveryDateFrom");

    ArrayList exceptions = new ArrayList(100);

// 2008-11-04 v1.4 D.Nihei Mod Start 統合障害#104対応
//    if (XxcmnUtility.isBlankOrNull(fdDate))
    // 発注No
    Object poNum  = poResultsSearchRow.getAttribute("PoNum");
    if (XxcmnUtility.isBlankOrNull(poNum) 
     && XxcmnUtility.isBlankOrNull(fdDate))
// 2008-11-04 v1.4 D.Nihei Mod End
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            poResultsSearchVo.getName(),
                            poResultsSearchRow.getKey(),
                            "DeliveryDateFrom",
                            fdDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));

      OAException.raiseBundledOAException(exceptions);
    }

  }

  /***************************************************************************
   * (検索画面)ページングの際にチェックボックスをOFFにします。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void checkBoxOff() throws OAException
  {
    // 発注情報VO取得
    OAViewObject vo = getXxpoSupplierResultsVO1();
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
   * (検索画面)処理対象行選択チェックを行います。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void chkSelect() throws OAException
  {
    // 発注情報VO取得
    OAViewObject vo = getXxpoSupplierResultsVO1();
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
   * (検索画面)一括出庫処理を行います。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doBatchDelivery() throws OAException
  {

    ArrayList exceptions = new ArrayList(100);

    // 発注情報VO取得
    OAViewObject vo = getXxpoSupplierResultsVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    // 発注明細VOを取得
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];
      
      String hdrId = row.getAttribute("HeaderId").toString();

      if (sb.length() > 0)
      {
        sb.append(", ");
      }

      sb.append(hdrId);
    }

    // 検索実施
    XxpoSupplierResultsDetailsVOImpl resultsDetailsVo = getXxpoSupplierResultsDetailsVO1();
    resultsDetailsVo.initQuery(sb.toString());
    resultsDetailsVo.getRowCount();
   
    // チェック処理
    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      boolean retFlag;

      // *************************************************** //
      // * 処理3:出庫実績存在チェック                         * //
      // * 処理4:OPM在庫会計CLOSEチェック                     * //
      // * 処理5:発注ステータスチェック                        * //
      // * 処理6:発注明細金額確定チェック                      * //
      // *************************************************** //
      retFlag = chkBatchDelivery(exceptions,
                                 vo,
                                 row);

      // チェックでエラーが発生した場合、後続処理はスキップ
      if (retFlag)
      {
        continue;
      }

      // *************************************************** //
      // * 処理7:発注明細更新処理                             * //
      // *************************************************** //
      detailsUpdate(row, resultsDetailsVo);
      
    }

    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      doRollBack();
      OAException.raiseBundledOAException(exceptions);

    // 例外が発生していない場合は、コミット処理
    } else 
    {

      // 発注明細情報更新コミット
      doCommit();

      String retCode = doDSResultsMake();

      if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
      {
        // 要求発行
        doCommit();         

        // 更新完了メッセージ
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30050,
          null,
          OAException.INFORMATION,
          null);

      }
    }

  } // doBatchDelivery

  /***************************************************************************
   * (検索画面)一括出庫処理の事前チェックを行います。
   * @param exceptions エラーリスト
   * @param vo 発注明細VO
   * @param row 処理対象発注データ
   * @return boolean エラー発生:true、エラー無し:false
   * @throws OAException OA例外
   ***************************************************************************
   */
  public boolean chkBatchDelivery(
    ArrayList exceptions,
    OAViewObject vo,
    OARow row
  ) throws OAException
  {

    boolean retFlag;
// 2011-06-01 v1.7 K.Kubo Add Start
    Number headerId     = (Number)row.getAttribute("HeaderId");      // 発注ヘッダID
    String headerNumber = (String)row.getAttribute("HeaderNumber");  // 発注番号

    // *************************************************** //
    // * 処理:仕入実績情報チェック                       * //
    // *************************************************** //
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
// 2011-06-01 v1.7 K.Kubo Add End

    // *************************************************** //
    // * 処理3:出庫実績存在チェック                         * //
    // *************************************************** //
// 2011-06-01 v1.7 K.Kubo DEL Start
//    String headerNumber = (String)row.getAttribute("HeaderNumber"); // 発注番号
// 2011-06-01 v1.7 K.Kubo DEL End

    // 出庫実績チェック
    String chkFlag = XxpoUtility.chkDeliveryResults(
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
                            XxpoConstants.XXPO10207,
                            null));

      // エラーあり
      return true;
    }

    // *************************************************** //
    // * 処理4:OPM在庫会計CLOSEチェック                  * //
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
                            XxpoConstants.XXPO10140,
                            null));
                            
      // エラーあり
      return true;
    }
// 2008-07-11 H.Itou Add START 納入日が未来日の場合、エラー
    // *************************************************** //
    // * 処理4-1:納入日未来日チェック                    * //
    // *************************************************** //
    // 直送区分が3：支給かつ、支給Noに入力ありの場合、納入日
    String dShipCode     = (String)row.getAttribute("DropshipCode"); // 直送区分コード
    String requestNumber = (String)row.getAttribute("RequestNumber");// 支給No

    if (XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
      && !XxcmnUtility.isBlankOrNull(requestNumber))
    {
      // 納入日＞システム日付はエラー
      if (XxcmnUtility.chkCompareDate(1, deliveryDate, XxpoUtility.getSysdate(getOADBTransaction())))
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
                              XxpoConstants.XXPO10253,
                              null));
                            
        // エラーあり
        return true;
      }
    }
// 2008-07-11 H.Itou Add END

    // *************************************************** //
    // * 処理5:発注ステータスチェック                  * //
    // *************************************************** //
    String statusCode = (String)row.getAttribute("StatusCode");
    String statusDisp = (String)row.getAttribute("StatusDisp");

    // 発注ステータスが、『取消』の場合
    if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
    {
      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10142,
                            null));
                            
      // エラーあり
      return true;

    // 発注ステータスが、『金額確定済』の場合
    } else if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10141,
                            null));
                            
      // エラーあり
      return true;
    }

    // *************************************************** //
    // * 処理6:発注明細金額確定チェック                  * //
    // *************************************************** //
    String chkMoneyDecisionFlag = XxpoUtility.getMoneyDecisionFlag(
                                    getOADBTransaction(),
                                    headerNumber);

    // 発注明細に金額確定済の明細が存在する場合
    if (XxcmnConstants.STRING_Y.equals(chkMoneyDecisionFlag))
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
                            XxpoConstants.XXPO10208,
                            null));
                            
      // エラーあり
      return true;
    }
   
// 2011-06-01 v1.7 K.Kubo Add Start
    // 事前チェックで問題ない且つ、
    // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ
    // 仕入実績作成処理管理Tblにデータを登録
    if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
      && !XxcmnUtility.isBlankOrNull(requestNumber)) 
    {

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
    }
// 2011-06-01 v1.7 K.Kubo Add End
    // エラー無し
    return false;
  } // 
  

  /***************************************************************************
   * (検索画面)発注明細UPDATE処理を行うメソッドです。
   * @param supplierResultsRow 検索結果VOの行
   * @param detailsVO 発注明細VO
   * @return String - 正常：TRUE、エラー：FALSE
   ***************************************************************************
   */
  public String detailsUpdate(OARow supplierResultsRow, OAViewObject detailsVO)
  {
  
    // 明細VOデータ取得
    HashMap params = new HashMap();

    // 発注ヘッダを取得
    Number headerId = (Number)supplierResultsRow.getAttribute("HeaderId");
    
    // 発注明細(フィルタリング)
    Row[] rows = detailsVO.getFilteredRows("PoHeaderId", headerId);

    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

// 2008-12-06 T.Yoshimoto Add Start 
      // *************************************************** //
      // * 処理:発注明細取消済みチェック                   * //
      // *************************************************** //
      String cancelFlag = (String)row.getAttribute("CancelFlag");

      if (XxcmnConstants.STRING_Y.equals(cancelFlag))
      {
         // エラーあり
         continue;   
      }
// 2008-12-06 T.Yoshimoto Add End

      // ヘッダーID
      params.put("HeaderId",          headerId.toString());
      // 明細ID
      params.put("LineId",            row.getAttribute("LineId").toString());
      // 納入日
      params.put("DeliveryDate",      supplierResultsRow.getAttribute("DeliveryDate"));
      
      // 仕入先出荷数量
      String orderAmount = (String)row.getAttribute("OrderAmount");
      orderAmount = XxcmnUtility.commaRemoval(orderAmount);

      params.put("LeavingShedAmount", orderAmount);
      // 入数
      params.put("ItemAmount",        row.getAttribute("ItemAmount"));
      // 日付指定
      params.put("AppointmentDate",   row.getAttribute("AppointmentDate"));
      // 明細摘要
      params.put("Description",   row.getAttribute("Description"));
      // 最終更新日
      params.put("LastUpdateDate",    row.getAttribute("LastUpdateDate"));

      // ロック取得処理
      getDetailsRowLock(params);

      // 排他制御
      chkDetailsExclusiveControl(params);

      // 仕入先出荷実績明細更新：実行
      XxpoUtility.updatePoLinesAllTxns(
        getOADBTransaction(), // トランザクション
        params                // パラメータ
        );
    }
    
    return XxcmnConstants.STRING_TRUE;
              
  }

  /***************************************************************************
   * (検索画面)コンカレント：直送仕入・出荷実績作成処理です。
   * @return String - リターンコード
   ***************************************************************************
   */
  public String doDSResultsMake()
  {

    // 検索結果VO取得
    OAViewObject supplierResultsVO = getXxpoSupplierResultsVO1();

    Row[] rows = supplierResultsVO.getFilteredRows("Selection", XxcmnConstants.STRING_Y);      

    // 選択されている発注情報を対象に、コンカレント起動処理
    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      // 直送区分コード
      String dShipCode = (String)row.getAttribute("DropshipCode");

      // 支給No.
      String requestNumber = (String)row.getAttribute("RequestNumber");

      // 発注No
      String headerNumber = (String)row.getAttribute("HeaderNumber");

// 2008-12-16 v1.6 T.Yoshimoto Add Start 本番#689
      // 発注ヘッダID
      Number headerId     = (Number)row.getAttribute("HeaderId");
    
      // リターン
      String retFlag      = XxcmnConstants.RETURN_NOT_EXE;
// 2008-12-16 v1.6 T.Yoshimoto Add Start 本番#689

      // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ実行
      if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
        && !XxcmnUtility.isBlankOrNull(requestNumber)) 
      {
        HashMap params = new HashMap(3);

        params.put("DropShipCode",  dShipCode);
        params.put("RequestNumber", requestNumber);
        params.put("HeaderNumber",  headerNumber);
// 2008-12-16 v1.6 T.Yoshimoto Mod Start 本番#689
        //return XxpoUtility.doDropShipResultsMake(
        retFlag = XxpoUtility.doDropShipResultsMake(
                              getOADBTransaction(), // トランザクション
                              params                // パラメータ
                              );

        // コンカレント正常起動後、ステータスを金額確定へ変更
        if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
        {
          XxpoUtility.updateStatusCode(
                        getOADBTransaction(),                        // トランザクション
                        XxpoConstants.STATUS_FINISH_DECISION_AMOUNT, // ステータス(数量確定)
                        headerId                                     // 発注ヘッダID
                              );
        }
// 2008-12-16 v1.6 T.Yoshimoto Mod Start 本番#689
      }
      
    }
    
    return XxcmnConstants.RETURN_SUCCESS;
  } // doDSResultsMake

  /***************************************************************************
   * (登録画面)初期化処理を行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   ***************************************************************************
   */
  public void initialize2(
    HashMap searchParams
  )
  {
      
    // ******************************************* //
    // * 仕入先出荷実績:登録ヘッダPVO 空行取得   * //
    // ******************************************* //
    OAViewObject resultsMakeHdrPVO = getXxpoSupplierResultsMakePVO1();

    // 1行もない場合、空行作成
    if (!resultsMakeHdrPVO.isPreparedForExecution())
    {    
      // 1行もない場合、空行作成
      resultsMakeHdrPVO.setMaxFetchSize(0);
      resultsMakeHdrPVO.executeQuery();
      resultsMakeHdrPVO.insertRow(resultsMakeHdrPVO.createRow());
    }

    // 1行目を取得
    OARow resultsMakeHdrPVORow = (OARow)resultsMakeHdrPVO.first();
    // キーに値をセット
    resultsMakeHdrPVORow.setAttribute("RowKey", new Number(1));
 
    // *********************************************** //
    // * 仕入先出荷実績:登録ヘッダVO 初期表示行取得  * //
    // *********************************************** //
    XxpoSupplierResultsMakeHdrVOImpl resultsMakeHdrVo = getXxpoSupplierResultsMakeHdrVO1();
    OARow resultsMakeHdrVORow = null;

    // 検索実施
    resultsMakeHdrVo.initQuery(searchParams);

// 20080228 add Start
    // パラメータがNullの場合、エラーページへ遷移する
    if (resultsMakeHdrVo.getRowCount() == 0) 
    {
      resultsMakeHdrPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

      // ************************ //
      // * エラーメッセージ出力 *
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500, 
                  null, 
                  OAException.ERROR, 
                  null);      
    }
// 20080228 add End

    resultsMakeHdrVORow = (OARow)resultsMakeHdrVo.first();
    
    // ***************************************** //
    // * 仕入先出荷実績:登録ヘッダVO 入力制御  * //
    // ***************************************** //
    String statusCode = (String)resultsMakeHdrVORow.getAttribute("StatusCode");

    // ステータスが"金額確定済"(35)の場合
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      // ヘッダの入力制御を実施
      readOnlyChangedHeader();
// 2008-11-04 v1.4 D.Nihei Add Start 
    } else
    {
      // 摘要を初期化する
      resultsMakeHdrPVORow.setAttribute("DescriptionReadOnly", Boolean.FALSE);
// 2008-11-04 v1.4 D.Nihei Add End
    }

    
    // ********************************************* //
    // * 仕入先出荷実績:登録明細VO 初期表示行取得  * //
    // ********************************************* //
    String hdrId = resultsMakeHdrVORow.getAttribute("HeaderId").toString();
    XxpoSupplierResultsDetailsVOImpl resultsDetailsVo = getXxpoSupplierResultsDetailsVO1();

    // 検索実施
    resultsDetailsVo.initQuery(hdrId);

// 20080228 add Start
    // パラメータがNullの場合、エラーページへ遷移する
    if (resultsDetailsVo.getRowCount() == 0) 
    {
      resultsMakeHdrPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

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
// 20080228 add End

    resultsDetailsVo.first();

    // ************************************************* //
    // * 仕入先出荷実績:登録明細合計VO 初期表示行取得  * //
    // ************************************************* //
    XxpoSupplierResultsTotalVOImpl resultsTotalVo = getXxpoSupplierResultsTotalVO1();

    // 検索実施
    resultsTotalVo.initQuery(hdrId);
    resultsTotalVo.first();


    // ***************************************** //
    // * 仕入先出荷実績:登録明細VO 入力制御    * //
    // ***************************************** //
    readOnlyChangedDetails();

  } // initialize2

  /***************************************************************************
   * (登録画面)入力制御(ヘッダー)を行うメソッドです。
   ***************************************************************************
   */
  public void readOnlyChangedHeader()
  {
    // 仕入先出荷実績:登録ヘッダVO取得
    OAViewObject resultsMakeHdrPVO = getXxpoSupplierResultsMakePVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)resultsMakeHdrPVO.first();

    // ヘッダ.摘要を読取専用に変更
    readOnlyRow.setAttribute("DescriptionReadOnly", Boolean.TRUE);
  }

  /***************************************************************************
   * (登録画面)入力制御(明細)を行うメソッドです。
   ***************************************************************************
   */
  public void readOnlyChangedDetails()
  {
    // 仕入先出荷実績:登録明細VO取得
    OAViewObject resultsMakeDetailsVO = getXxpoSupplierResultsDetailsVO1();
    OARow resultsMakeDetailsVORow = null;

    // 仕入先出荷実績:登録明細VOのフェッチ行数を取得
    int detailsCount = resultsMakeDetailsVO.getFetchedRowCount();

    if (detailsCount > 0) 
    {
      // 金額確定フラグ(N：未承諾、Y：承諾済み)
      String moneyDecisionFlag = null;
      // 品目区分
      String itemClassCode = null;
      // 商品区分
      String prodClassCode = null;
      // 入出庫換算単位
      String convUnit      = null;
// 2008-12-06 H.Itou Mod Start
      String cancelFlag = null; // 取消フラグ
// 2008-12-06 H.Itou Mod End
      
      // 1行目
      resultsMakeDetailsVO.first();
      
      while (resultsMakeDetailsVO.getCurrentRow() != null)
      {
        resultsMakeDetailsVORow = (OARow)resultsMakeDetailsVO.getCurrentRow();

        moneyDecisionFlag = (String)resultsMakeDetailsVORow.getAttribute("MoneyDecisionFlag");
        itemClassCode     = (String)resultsMakeDetailsVORow.getAttribute("ItemClassCode");
        prodClassCode     = (String)resultsMakeDetailsVORow.getAttribute("ProdClassCode");
        convUnit          = (String)resultsMakeDetailsVORow.getAttribute("ConvUnit");
// 2008-12-06 H.Itou Mod Start
        cancelFlag = (String)resultsMakeDetailsVORow.getAttribute("CancelFlag");
// 2008-12-06 H.Itou Mod End
        
        // 金額確定フラグが"Y"(承諾済)の場合もReadOnly処理
// 2008-12-06 H.Itou Mod Start 取消フラグがYの場合、ReadOnly
//        if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
        if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag)
         || XxcmnConstants.STRING_Y.equals(cancelFlag))
// 2008-12-06 H.Itou Mod End
        {
          readOnlyChangedMoneyFlag(resultsMakeDetailsVORow);

        } else
        {
        
          // ***************************************** //
          // * 品目が製品の場合、製造日は編集不可    * //
          // ***************************************** //
          if (!XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
          {
            // 明細.製造日
            resultsMakeDetailsVORow.setAttribute("ProductionDateReadOnly",    Boolean.FALSE);

          } else
          {
            // 明細.製造日
            resultsMakeDetailsVORow.setAttribute("ProductionDateReadOnly",    Boolean.TRUE);
          }

          // ******************************************************* //
          // * ドリンク製品(換算単位あり)の場合、入数は編集不可    * //
          // ******************************************************* //
          if (chkConversion(prodClassCode, itemClassCode, convUnit))
          {
            // 明細.入数
            resultsMakeDetailsVORow.setAttribute("ItemAmountReadOnly",    Boolean.TRUE);

          } else
          {
            // 明細.入数
            resultsMakeDetailsVORow.setAttribute("ItemAmountReadOnly",    Boolean.FALSE);
          }

        }
        resultsMakeDetailsVO.next();
        
      }
// 20080626 Add Start
      resultsMakeDetailsVO.first();
// 20080626 Add End
    }

  }

  /***************************************************************************
   * (登録画面)入力制御(明細)を金額確定フラグに伴うreadOnly設定を行うメソッドです。
   * @param resultsMakeDetailsVORow 発注明細VO
   ***************************************************************************
   */
  private void readOnlyChangedMoneyFlag(OARow resultsMakeDetailsVORow)
  {
    // 明細.入数
    resultsMakeDetailsVORow.setAttribute("ItemAmountReadOnly",        Boolean.TRUE);

    // 明細.製造日
    resultsMakeDetailsVORow.setAttribute("ProductionDateReadOnly",    Boolean.TRUE);

    // 明細.出庫数
    resultsMakeDetailsVORow.setAttribute("LeavingShedAmountReadOnly", Boolean.TRUE);

    // 明細.日付指定
    resultsMakeDetailsVORow.setAttribute("AppointmentDateReadOnly",   Boolean.TRUE);

    // 明細.賞味期限
    resultsMakeDetailsVORow.setAttribute("UseByDateReadOnly",         Boolean.TRUE);

    // 明細.摘要
    resultsMakeDetailsVORow.setAttribute("DescriptionReadOnly",       Boolean.TRUE);

    // 明細.ランク1,ランク2
    resultsMakeDetailsVORow.setAttribute("RankReadOnly",              Boolean.TRUE);

  }

  /***************************************************************************
   * (登録画面)製造日変更時処理です。
   * @param params パラメータ用HashMap
   ***************************************************************************
   */
  public void productedDateChanged(HashMap params)
  {        
    // 賞味期限取得
    getUseByDate(params);
  }

  /***************************************************************************
   * (登録画面)賞味期限を取得するメソッドです。
   * @param params パラメータ用HashMap
   ***************************************************************************
   */
  public void getUseByDate(HashMap params)
  {
    String searchLineNum = 
      (String)params.get(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);
    
    // 仕入先出荷実績情報:登録明細VO取得
    OAViewObject supplierResultsDetailsVo = getXxpoSupplierResultsDetailsVO1();
    // 1行めを取得
    OARow supplierResultsDetailRow = null;

    supplierResultsDetailsVo.first();

    while(supplierResultsDetailsVo.getCurrentRow() != null)
    {
      supplierResultsDetailRow = (OARow)supplierResultsDetailsVo.getCurrentRow();
      if (searchLineNum.equals(supplierResultsDetailRow.getAttribute("LineNum").toString())) 
      {
        break;
      }
      supplierResultsDetailsVo.next();
    }

    // データ取得
    Date productedDate   = (Date)supplierResultsDetailRow.getAttribute("ProductionDate");   // 製造日
    Number itemId        = (Number)supplierResultsDetailRow.getAttribute("ItemId");        // 品目ID
    Number expirationDay = (Number)supplierResultsDetailRow.getAttribute("ExpirationDate"); // 賞味期間

    // 製造日が入力されていない(削除された)場合は算出を行わない
    if (productedDate != null) {
      // 賞味期間に値がある場合、賞味期限取得
      if (XxcmnUtility.isBlankOrNull(expirationDay) == false)
      {
// 20080226 mod Start
        Date useByDate = XxpoUtility.getUseByDate(
// 20080226 mod End
                           getOADBTransaction(),     // トランザクション
                           itemId,                   // INV品目ID
                           productedDate,            // 製造日
                           expirationDay.toString()  // 賞味期間
                         );

        // 賞味期限を外注出来高情報:登録VOにセット
        supplierResultsDetailRow.setAttribute("UseByDate", useByDate);
    
      // 賞味期間に値がない場合、NULL
      } else
      {
        // 賞味期限を仕入先出荷実績情報:登録明細VOにセット
        supplierResultsDetailRow.setAttribute("UseByDate", productedDate);      
      }
    }
  }

  /***************************************************************************
   * (登録画面)登録・更新時のチェックを行います。
   ***************************************************************************
   */
  public void allCheck()
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);

    // ******************************* //
    // *   入力値チェック            * //
    // ******************************* //
    messageTextCheck(exceptions);
    
    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // ******************************* //
    // *   更新条件チェック          * //
    // ******************************* //
    updateConditionCheck(exceptions);
    
    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    
  }

  /***************************************************************************
   * (登録画面)入力値チェックを行うメソッドです。
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 仕入先出荷実績情報:登録明細VO取得
    OAViewObject supplierResultsDetailsVo = getXxpoSupplierResultsDetailsVO1();

    OARow supplierResultsDetailsVORow = null;

    // 1行目   
    supplierResultsDetailsVo.first();

    // レコードが取得できる間、チェックを実施
    while(supplierResultsDetailsVo.getCurrentRow() != null)
    {
      supplierResultsDetailsVORow = (OARow)supplierResultsDetailsVo.getCurrentRow();

      // 行単位での入力チェックを実施
      messageTextRowCheck(supplierResultsDetailsVo,
                          supplierResultsDetailsVORow,
                          exceptions);

      supplierResultsDetailsVo.next();
    }
  }

  /***************************************************************************
   * (登録画面)行単位で入力値チェックを行うメソッドです。
   * @param checkVo チェック対象VO
   * @param checkRow チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void messageTextRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException 
  {
    // 入数を取得
    String itemAmount = (String)checkRow.getAttribute("ItemAmount");

    // 出庫数を取得
    String leavingShedAmount = (String)checkRow.getAttribute("LeavingShedAmount");


    // ******************************* //
    // *   入力必須チェック            * //
    // ******************************* //
    // 入数：必須チェック
    if (XxcmnUtility.isBlankOrNull(itemAmount)) 
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY1, XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_ENTRY2, XxpoConstants.TOKEN_NAME_L_S_AMOUNT);

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            checkVo.getName(),
                            checkRow.getKey(),
                            "ItemAmount",
                            itemAmount,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10071,
                            tokens));
      
    }

    // 出庫数：必須チェック
    if (XxcmnUtility.isBlankOrNull(leavingShedAmount)) 
    {

      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY1, XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_ENTRY2, XxpoConstants.TOKEN_NAME_L_S_AMOUNT);

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            checkVo.getName(),
                            checkRow.getKey(),
                            "LeavingShedAmount",
                            leavingShedAmount,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10071,
                            tokens));
    }

    // ******************************* //
    // *   入力値チェック            * //
    // ******************************* //
    //** 入数が正の数(0より大きい) **//
    if (!XxcmnUtility.isBlankOrNull(itemAmount)) 
    {

      // 数値でない場合はエラー
      if (!XxcmnUtility.chkNumeric(itemAmount, 5, 3)) 
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
      } else if(!XxcmnUtility.chkCompareNumeric(1, itemAmount, "0"))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);
      
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

      checkRow.setAttribute("ItemAmount", itemAmount);

    }

    //** 出庫数が0以上 **//
    if (!XxcmnUtility.isBlankOrNull(leavingShedAmount)) 
    {

      // 数値でない場合はエラー
      if (!XxcmnUtility.chkNumeric(leavingShedAmount, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              checkVo.getName(),
                              checkRow.getKey(),
                              "LeavingShedAmount",
                              leavingShedAmount,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

      // 0以下はエラー
      } else if(!XxcmnUtility.chkCompareNumeric(2, leavingShedAmount, "0"))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_L_S_AMOUNT);
      
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              checkVo.getName(),
                              checkRow.getKey(),
                              "LeavingShedAmount",
                              leavingShedAmount,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10068,
                              tokens));
      }

      checkRow.setAttribute("LeavingShedAmount", leavingShedAmount);

    }    
  }

  /***************************************************************************
   * (登録画面)更新条件チェックを行うメソッドです。
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void updateConditionCheck(
    ArrayList exceptions
  ) throws OAException 
  {

    // ******************************* //
    // *   ヘッダー関連チェック      * //
    // ******************************* //    
    updateConditionHdrCheck(exceptions);

    // ******************************* //
    // *   明細関連チェック      * //
    // ******************************* //    
    updateConditioDetailCheck(exceptions);

  }

  /***************************************************************************
   * (登録画面)ヘッダー関連の更新条件チェックを行うメソッドです。
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void updateConditionHdrCheck(
    ArrayList exceptions
  ) throws OAException 
  {
  
    // 仕入先出荷実績情報:登録ヘッダーVO取得
    OAViewObject supplierResultsMakeHdrVo = getXxpoSupplierResultsMakeHdrVO1();
    // 1行目を取得
    OARow supplierResultsMakeHdrVORow = (OARow)supplierResultsMakeHdrVo.first();

// 2011-06-01 v1.7 K.Kubo Add Start
    // 仕入実績作成処理管理Tblにデータが存在する場合、
    // 処理を中断する。
    String headerNumber = (String)supplierResultsMakeHdrVORow.getAttribute("HeaderNumber"); // 発注No取得
    Number headerId     = (Number)supplierResultsMakeHdrVORow.getAttribute("HeaderId");     // 発注ヘッダID取得

    // *************************************************** //
    // * 処理:仕入実績情報チェック                       * //
    // *************************************************** //
    String retFlag  = XxpoUtility.chkStockResult(
                                    getOADBTransaction(),     // トランザクション
                                    headerId                  // 発注ヘッダID
                      );
    // 同一データが存在する場合（エラーが返ってきた場合）
    if (!(XxcmnConstants.RETURN_NOT_EXE.equals(retFlag)))
    {
      // ************************ //
      // * エラーメッセージ出力 * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
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

// 2011-06-01 v1.7 K.Kubo Add End

    // ******************************* //
    // *   在庫クローズチェック      * //
    // ******************************* // 
    Date deliveryDate  = 
      (Date)supplierResultsMakeHdrVORow.getAttribute("DeliveryDate"); // 納入日取得
    
    if (XxpoUtility.chkStockClose(
          getOADBTransaction(), // トランザクション
          deliveryDate)         // 納入日
        )
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10140));

    }

// 2008-07-11 H.Itou Add START 納入日が未来日の場合、エラー
    // *************************************************** //
    // * 処理4-1:納入日未来日チェック                    * //
    // *************************************************** //
    // 直送区分が3：支給かつ、支給Noに入力ありの場合、納入日
      String dShipCode     = (String)supplierResultsMakeHdrVORow.getAttribute("DropshipCode"); // 直送区分コード
      String requestNumber = (String)supplierResultsMakeHdrVORow.getAttribute("RequestNumber");// 支給No

      if (XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
        && !XxcmnUtility.isBlankOrNull(requestNumber))
      {
        // 納入日＞システム日付はエラー
        if (XxcmnUtility.chkCompareDate(1, deliveryDate, XxpoUtility.getSysdate(getOADBTransaction())))
        {
          // ************************ //
          // * エラーメッセージ出力 * //
          // ************************ //
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                supplierResultsMakeHdrVo.getName(),
                                supplierResultsMakeHdrVORow.getKey(),
                                "DeliveryDate",
                                deliveryDate,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10254,
                                null));
        }
      }
// 2008-07-11 H.Itou Add END

    // ************************************* //
    // *   金額確定済みフラグチェック      * //
    // ************************************* //
    String statusCode  = 
      (String)supplierResultsMakeHdrVORow.getAttribute("StatusCode"); // ステータスコード取得
    String statusDisp =
      (String)supplierResultsMakeHdrVORow.getAttribute("StatusDisp"); // ステータス名取得
// 2008-10-22 T.Yoshimoto Aod START
// 2011-06-01 v1.7 K.Kubo DEL Start
//    String headerNumber =
//      (String)supplierResultsMakeHdrVORow.getAttribute("HeaderNumber"); // 発注No取得
// 2011-06-01 v1.7 K.Kubo DEL End
// 2008-10-22 T.Yoshimoto Aod END      
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
// 2008-10-22 T.Yoshimoto Mod START
//                            "StatusDisp",
//                            statusDisp,
                            "HeaderNumber",
                            headerNumber,
// 2008-10-22 T.Yoshimoto Mod END
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10141));      
    }

    // ********************************* //
    // *   取消済みフラグチェック      * //
    // ********************************* //
    if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10142));      
    }
  }


  /***************************************************************************
   * (登録画面)明細関連の更新条件チェックを行うメソッドです。
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void updateConditioDetailCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 仕入先出荷実績情報:登録明細VO取得
    OAViewObject supplierResultsDetailsVo = getXxpoSupplierResultsDetailsVO1();

    OARow supplierResultsDetailsVORow = null;

    // 1行目   
    supplierResultsDetailsVo.first();

    // レコードが取得できる間、チェックを実施
    while(supplierResultsDetailsVo.getCurrentRow() != null)
    {
      supplierResultsDetailsVORow = (OARow)supplierResultsDetailsVo.getCurrentRow();

      // 行単位での金額確定フラグチェックを実施
      updateConditioDetailRowCheck(supplierResultsDetailsVo,
                                   supplierResultsDetailsVORow,
                                   exceptions);

      supplierResultsDetailsVo.next();
    }
// 2011-06-01 v1.7 K.Kubo Add Start
    // 事前チェックで問題ない場合、
    // 仕入実績作成処理管理Tblにデータを登録

    // 仕入先出荷実績情報:登録ヘッダーVO取得
    OAViewObject supplierResultsMakeHdrVo = getXxpoSupplierResultsMakeHdrVO1();
    // 1行目を取得
    OARow supplierResultsMakeHdrVORow = (OARow)supplierResultsMakeHdrVo.first();

    // 直送区分及び、支給Noを取得
    String dShipCode     = (String)supplierResultsMakeHdrVORow.getAttribute("DropshipCode"); // 直送区分コード
    String requestNumber = (String)supplierResultsMakeHdrVORow.getAttribute("RequestNumber");// 支給No

    // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ
    // 仕入実績作成処理管理Tblにデータを登録
    if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
      && !XxcmnUtility.isBlankOrNull(requestNumber))
    {
      String headerNumber = (String)supplierResultsMakeHdrVORow.getAttribute("HeaderNumber"); // 発注No取得
      Number headerId     = (Number)supplierResultsMakeHdrVORow.getAttribute("HeaderId");     // 発注ヘッダID取得
  
      // ************************ //
      // * 仕入実績情報登録     * //
      // ************************ //
      String retFlag2 = XxpoUtility.insStockResult(
                                      getOADBTransaction()      // トランザクション
                                     ,headerId                  // 発注ヘッダID
                                     ,headerNumber              // 発注番号
                        );
      // 正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag2))
      {
        //トークン生成
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                   XxpoConstants.TOKEN_NAME_STOCK_RESULT_MANEGEMENT) };
        throw new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              supplierResultsMakeHdrVo.getName(),
                              supplierResultsMakeHdrVORow.getKey(),
                              "HeaderNumber",
                              headerNumber,
                              XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN05002,
                              tokens);
      }
    }
// 2011-06-01 v1.7 K.Kubo Add End
  }

  /***************************************************************************
   * (登録画面)行単位で更新条件(金額確定フラグOFF)チェックを行うメソッドです。
   * @param checkVo チェック対象VO
   * @param checkRow チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void updateConditioDetailRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException 
  {

    String moneyDecisionFlag = (String)checkRow.getAttribute("MoneyDecisionFlag");
    
    if (XxcmnConstants.STRING_Y.equals(moneyDecisionFlag)) 
    {
        
      exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          checkVo.getName(),
                          checkRow.getKey(),
                          "MoneyDecisionFlag",
                          moneyDecisionFlag,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10141));
    }

  }

  /***************************************************************************
   * (登録画面)更新処理を行うメソッドです。
   * @return String リターンコード(正常(更新有)：HeaderID、正常(更新無)：TRUE、エラー：FALSE)
   ***************************************************************************
   */
  public String Apply()
  {

    String retCode = XxcmnConstants.STRING_TRUE;
    String updFlag = XxcmnConstants.STRING_N;
// 2008-10-22 T.Yoshimoto ADD START
    String requestNumber;
    String dShipCode;
// 2008-10-22 T.Yoshimoto ADD END

    OAViewObject makeHdrVO = getXxpoSupplierResultsMakeHdrVO1();
    OARow makeHdrVORow = (OARow)makeHdrVO.first();

    // *************************** //
    // *   ヘッダー更新処理      * //
    // *************************** //
    if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("Description"),               
                               makeHdrVORow.getAttribute("BaseDescription")))    // 摘要(ヘッダー)：摘要(ヘッダー)(DB)
    {

// 2008-10-22 T.Yoshimoto ADD START
      // 支給Noを取得
      requestNumber = (String)makeHdrVORow.getAttribute("RequestNumber");
      // 直送区分コード
      dShipCode     = (String)makeHdrVORow.getAttribute("DropshipCode");

      // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ実行
      if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
        && !XxcmnUtility.isBlankOrNull(requestNumber)) 
      {
        // ****************************************************** //
        // * 有償金額確定チェック(確定済みの場合、処理を中断)   * //
        // ****************************************************** //
        if (XxpoUtility.chkAmountFixClass(getOADBTransaction(), requestNumber))
        {

          // ************************ //
          // * エラーメッセージ出力 * //
          // ************************ //
          throw new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            makeHdrVO.getName(),
                            makeHdrVORow.getKey(),
                            "RequestNumber",
                            requestNumber,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10141);
        } 
      }
// 2008-10-22 T.Yoshimoto ADD END

      // 発注ヘッダー更新処理
      retCode = headerUpdate(makeHdrVORow);

      // ヘッダー更新処理でエラーが発生した場合、処理を中断
      if (XxcmnConstants.STRING_FALSE.equals(retCode)) 
      {
        return retCode;
      }
    
      // 20080225 add Start
      updFlag = XxcmnConstants.STRING_Y;
      // 20080225 add End
    }

    // *********************** //
    // *   明細更新処理      * //
    // *********************** //
    OAViewObject makeDetailsVO = getXxpoSupplierResultsDetailsVO1();
    OARow makeDetailsVORow = null;

    makeDetailsVO.first();
   
    while(makeDetailsVO.getCurrentRow() != null)
    {

      makeDetailsVORow = (OARow)makeDetailsVO.getCurrentRow();
// 2008-12-06 H.Itou Mod Start
      // 明細削除フラグYの場合、登録処理を行わない
      String cancelFlag = (String)makeDetailsVORow.getAttribute("CancelFlag");
      if (XxcmnConstants.STRING_Y.equals(cancelFlag))
      {
        // VOを次行へ移動
        makeDetailsVO.next();
        continue;
      }
// 2008-12-06 H.Itou Mod End

      if ((!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("ItemAmount"),               
                                 makeDetailsVORow.getAttribute("BaseItemAmount")))      // 入数：在庫入数(DB)
        || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("DeliveryDate"),               
                                 makeDetailsVORow.getAttribute("BaseShippingDate")))    // 納品日：仕入出荷日(DB)
        || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("LeavingShedAmount"),               
                                 makeDetailsVORow.getAttribute("BaseShippingAmount")))  // 出庫数：仕入先出荷数量(DB)
        || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("AppointmentDate"),               
                                 makeDetailsVORow.getAttribute("BaseAppointmentDate"))) // 日付指定：日付指定(DB)
        || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("Description"),               
                                 makeDetailsVORow.getAttribute("BaseDescription"))))    // 摘要(明細)：摘要(明細)(DB)
      {

// 2008-10-22 T.Yoshimoto ADD START
        // 支給Noを取得
        requestNumber = (String)makeHdrVORow.getAttribute("RequestNumber");
        // 直送区分コード
        dShipCode     = (String)makeHdrVORow.getAttribute("DropshipCode");

        // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ実行
        if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
          && !XxcmnUtility.isBlankOrNull(requestNumber)) 
        {
          // ****************************************************** //
          // * 有償金額確定チェック(確定済みの場合、処理を中断)   * //
          // ****************************************************** //
          if (XxpoUtility.chkAmountFixClass(getOADBTransaction(), requestNumber))
          {

            // ************************ //
            // * エラーメッセージ出力 * //
            // ************************ //
            throw new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              makeHdrVO.getName(),
                              makeHdrVORow.getKey(),
                              "RequestNumber",
                              requestNumber,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10141);
          } 
        }
// 2008-10-22 T.Yoshimoto ADD END

        // 発注明細更新処理
        retCode = detailsUpdate2(makeHdrVORow, makeDetailsVORow);

        // 発注明細更新処理でエラーが発生した場合、処理を中断
        if (XxcmnConstants.STRING_FALSE.equals(retCode)) 
        {

          return retCode;
        }

// 20080225 add Start
        updFlag = XxcmnConstants.STRING_Y;
// 20080225 add End
      }
      
      // VOを次行へ移動
      makeDetailsVO.next();
    }


    // ******************************** //
    // *   OPMロットマスタ更新処理    * //
    // ******************************** //
    makeDetailsVO.first();
    
    while(makeDetailsVO.getCurrentRow() != null)
    {

      makeDetailsVORow = (OARow)makeDetailsVO.getCurrentRow();
// 20080521 add yoshimoto Start 不具合ログ#320_3
      // 品目がロット対象である場合
      Number lotCtl = (Number)makeDetailsVORow.getAttribute("LotCtl");
      
      if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
      {
// 20080521 add yoshimoto End 不具合ログ#320_3

        if ( (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("ItemAmount"),               
                                     makeDetailsVORow.getAttribute("BaseIlmItemAmount")))   // 入数：OPMロットMST在庫入数(DB)
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("ProductionDate"),               
                                     makeDetailsVORow.getAttribute("BaseProductionDate")))  // 製造日：OPMロットMST製造年月日(DB)
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("UseByDate"),               
                                     makeDetailsVORow.getAttribute("BaseUseByDate")))       // 賞味期限：OPMロットMST賞味期限(DB)
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("Rank"),               
                                     makeDetailsVORow.getAttribute("BaseRank")))            // ランク1：OPMロットMSTランク1(DB)
// 2008-11-04 v1.4 D.Nihei Add Start 統合障害#51対応
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("Rank2"),               
                                     makeDetailsVORow.getAttribute("BaseRank2"))))          // ランク2：OPMロットMSTランク2(DB)
// 2008-11-04 v1.4 D.Nihei Add End
        {

// 2008-10-22 T.Yoshimoto ADD START
          // 支給Noを取得
          requestNumber = (String)makeHdrVORow.getAttribute("RequestNumber");
          // 直送区分コード
          dShipCode     = (String)makeHdrVORow.getAttribute("DropshipCode");

          // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ実行
          if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
            && !XxcmnUtility.isBlankOrNull(requestNumber)) 
          {
            // ****************************************************** //
            // * 有償金額確定チェック(確定済みの場合、処理を中断)   * //
            // ****************************************************** //
            if (XxpoUtility.chkAmountFixClass(getOADBTransaction(), requestNumber))
            {

              // ************************ //
              // * エラーメッセージ出力 * //
              // ************************ //
              throw new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                makeHdrVO.getName(),
                                makeHdrVORow.getKey(),
                                "RequestNumber",
                                requestNumber,
                                XxcmnConstants.APPL_XXPO,         
                                XxpoConstants.XXPO10141);
            } 
          }
// 2008-10-22 T.Yoshimoto ADD END

          // OPMロットマスタ更新処理
          retCode = opmLotMstUpdate(makeHdrVORow, makeDetailsVORow);
  
          // OPMロットマスタ更新処理でエラーが発生した場合、処理を中断
          if (XxcmnConstants.STRING_FALSE.equals(retCode)) 
          {
            return retCode;
          }
// 20080225 add Start
          updFlag = XxcmnConstants.STRING_Y;
// 20080225 add End
        }
// 20080521 add yoshimoto Start 不具合ログ#320_3
      }
// 20080521 add yoshimoto End 不具合ログ#320_3
      // VOを次行へ移動
      makeDetailsVO.next();
    }

// 20080225 add Start
    // 更新処理が正常に終了した場合、再検索用にヘッダーIDを戻す
    if (XxcmnConstants.STRING_Y.equals(updFlag)) 
    {
// 20080225 add End
      retCode = makeHdrVORow.getAttribute("HeaderId").toString();

    // 更新無し終了した場合、STRING_TRUEを戻す
    }else
    {
      retCode = XxcmnConstants.STRING_TRUE;
    }

    return retCode;
    
  }

  /***************************************************************************
   * (登録画面)発注ヘッダUPDATE処理を行うメソッドです。
   * @param makeHdrVORow 更新対象行
   * @return String 正常：TRUE、エラー：FALSE
   ***************************************************************************
   */
  public String headerUpdate(OARow makeHdrVORow)
  {
    // 仕入先出荷実績ヘッダーVOデータ取得
    HashMap params = new HashMap();

    // ヘッダーID
    params.put("HeaderId",    makeHdrVORow.getAttribute("HeaderId").toString());
    // 適用
    params.put("Description", makeHdrVORow.getAttribute("Description"));
    // 最終更新日
    params.put("LastUpdateDate", makeHdrVORow.getAttribute("LastUpdateDate"));

    // ロック取得処理
    getHeaderRowLock(params);

    // 排他制御
    chkHdrExclusiveControl(params);

    // 仕入先出荷実績ヘッダー更新：実行
    String retCode =  XxpoUtility.updatePoHeadersAllTxns(
                        getOADBTransaction(), // トランザクション
                        params                // パラメータ
                        );

    // 更新処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    } 

    return XxcmnConstants.STRING_TRUE;
    
  }

  /***************************************************************************
   * (登録画面)発注ヘッダのロック処理を行うメソッドです。
   * @param params パラメータ
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getHeaderRowLock(
    HashMap params
  ) throws OAException 
  {
   
    String apiName = "getHeaderRowLock";

    // ヘッダーId
    String headerId = (String)params.get("HeaderId");
    
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pha_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pha.po_header_id header_id "); // ヘッダーID
    sb.append("    FROM   PO_HEADERS_ALL pha ");         // 発注ヘッダ
    sb.append("    WHERE  pha.po_header_id = TO_NUMBER(:1) ");
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
      cstmt.setString(i++, headerId);
      
      cstmt.execute();

    } catch (SQLException s) 
    {
      // ロールバック
      doRollBack();
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        doRollBack();

        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getRowLock

  /***************************************************************************
   * (登録画面)発注ヘッダーの排他制御チェックを行うメソッドです。
   * @param params パラメータ用HashMap
   ***************************************************************************
   */
  public void chkHdrExclusiveControl(
    HashMap params)
  {
    String apiName  = "chkHdrExclusiveControl";
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pha.PO_HEADER_ID) cnt "); // 発注ヘッダID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   PO_HEADERS_ALL pha ");          // 発注ヘッダ
      sb.append("  WHERE  pha.PO_HEADER_ID = TO_NUMBER(:2) ");       // 発注ヘッダID
      sb.append("  AND    TO_CHAR(pha.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
                
      // 発注ヘッダ情報
      vo  = getXxpoSupplierResultsMakeHdrVO1();

      // 更新行取得
      row = (OARow)vo.first();
  
      // 各種情報を取得します。
      String headerId          = (String)params.get("HeaderId"); // 発注ヘッダID 
      String hdrLastUpdateDate = (String)params.get("LastUpdateDate"); // 最終更新日
      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, Integer.parseInt(headerId));
      cstmt.setString(i++, hdrLastUpdateDate);
      
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
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkHdrExclusiveControl

  /***************************************************************************
   * (登録画面)発注明細UPDATE処理を行うメソッドです。
   * @param makeHdrVORow ヘッダーVOの行
   * @param makeDetailsVORow 明細VOの行
   * @return String - 正常：TRUE、エラー：FALSE
   ***************************************************************************
   */
  public String detailsUpdate2(OARow makeHdrVORow, OARow makeDetailsVORow)
  {
    // 仕入先出荷実績明細VOデータ取得
    HashMap params = new HashMap();
    

    // ヘッダーID
    params.put("HeaderId",          makeDetailsVORow.getAttribute("PoHeaderId").toString());

    // 明細ID
    params.put("LineId",            makeDetailsVORow.getAttribute("LineId").toString());

    // 入数
    params.put("ItemAmount",        makeDetailsVORow.getAttribute("ItemAmount"));
    // 納品日
    params.put("DeliveryDate",      makeHdrVORow.getAttribute("DeliveryDate"));
    // 出庫数
    params.put("LeavingShedAmount", makeDetailsVORow.getAttribute("LeavingShedAmount"));
    // 日付指定
    params.put("AppointmentDate",   makeDetailsVORow.getAttribute("AppointmentDate"));
    // 適用(明細)
    params.put("Description",       makeDetailsVORow.getAttribute("Description"));
    // 最終更新日
    params.put("LastUpdateDate",    makeDetailsVORow.getAttribute("LastUpdateDate"));

    // ロック取得処理
    getDetailsRowLock(params);

    // 排他制御
    chkDetailsExclusiveControl(params);

    // 仕入先出荷実績明細更新：実行
    String retCode =  XxpoUtility.updatePoLinesAllTxns(
                        getOADBTransaction(), // トランザクション
                        params                // パラメータ
                        );

    // 更新処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    } 

    return XxcmnConstants.STRING_TRUE;
              
  }

  /***************************************************************************
   * (登録画面)発注明細のロック処理を行うメソッドです。
   * @param params パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getDetailsRowLock(
    HashMap params
  ) throws OAException 
  {

    String headerId = (String)params.get("HeaderId");
    String lineId   = (String)params.get("LineId");
    
    String apiName = "getDetailsRowLock";
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pla_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pla.po_line_id line_id "); // ヘッダーID
    sb.append("    FROM   PO_LINES_ALL pla ");           // 発注明細
    sb.append("    WHERE  pla.po_header_id = TO_NUMBER(:1) ");
    sb.append("    AND    pla.po_line_id   = TO_NUMBER(:2) ");
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
      int i = 1;
      cstmt.setString(i++, headerId);
      cstmt.setString(i++, lineId);
      
      cstmt.execute();

    } catch (SQLException s) 
    {
      // ロールバック
      doRollBack();
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        doRollBack();
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getDetailsRowLock

  /***************************************************************************
   * (登録画面)発注明細の排他制御チェックを行うメソッドです。
   * @param params パラメータ用HashMap
   ***************************************************************************
   */
  public void chkDetailsExclusiveControl(
    HashMap params
  )
  {
    String apiName  = "chkDetailsExclusiveControl";
    //OAViewObject vo = null;
    //OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pla.PO_LINE_ID) cnt "); // 発注ヘッダID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   PO_LINES_ALL pla ");            // 発注明細
      sb.append("  WHERE  pla.PO_HEADER_ID = TO_NUMBER(:2) ");       // 発注ヘッダID
      sb.append("  AND    pla.po_line_id   = TO_NUMBER(:3) ");        // 明細行番号
      sb.append("  AND    TO_CHAR(pla.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
                
      // 発注明細情報
      //vo  = getXxpoSupplierResultsDetailsVO1();
      //int fetchedRowCount = vo.getFetchedRowCount();
      
      
      // 各種情報を取得します。
      String headerId          = (String)params.get("HeaderId");       // 発注ヘッダID 
      String lineId            = (String)params.get("LineId");         // 更新対象明細ID
      String dtlLastUpdateDate = (String)params.get("LastUpdateDate"); // 最終更新日

      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, Integer.parseInt(headerId));
      cstmt.setInt(i++, Integer.parseInt(lineId));
      cstmt.setString(i++, dtlLastUpdateDate);
      
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
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkDetailsExclusiveControl


  /***************************************************************************
   * (登録画面)OPMロットマスタUPDATE処理を行うメソッドです。
   * @param makeHdrVORow ヘッダーVOの行
   * @param makeDetailsVORow 明細VOの行
   * @return String 正常：TRUE、エラー：FALSE
   ***************************************************************************
   */
  public String opmLotMstUpdate(OARow makeHdrVORow, OARow makeDetailsVORow)
  {    
    // 仕入先出荷実績明細VOデータ取得
    HashMap params = new HashMap();

    // 入数
    params.put("ItemAmount",        makeDetailsVORow.getAttribute("ItemAmount"));
    // 製造日
    params.put("ProductionDate",    makeDetailsVORow.getAttribute("ProductionDate"));
    // 賞味期限
    params.put("UseByDate",         makeDetailsVORow.getAttribute("UseByDate"));
    // ランク1
    params.put("Rank",              makeDetailsVORow.getAttribute("Rank"));
// 2008-11-04 v1.4 D.Nihei Add Start 統合障害#51対応 
    // ランク2
    params.put("Rank2",              makeDetailsVORow.getAttribute("Rank2"));
// 2008-11-04 v1.4 D.Nihei Add End
    // 品目ID
    params.put("ItemId",            makeDetailsVORow.getAttribute("ItemId"));
    // ロットNo
    params.put("LotNo",             makeDetailsVORow.getAttribute("LotNo"));
    // 最終更新日
    params.put("LotLastUpdateDate", makeDetailsVORow.getAttribute("LotLastUpdateDate"));

    // ロック取得処理
    getOpmLotMstRowLock(params);

    // 排他制御
    chkOpmLotMstExclusiveControl(params);

    // OPMロットマスタ更新：実行
    String retCode =  XxpoUtility.updateIcLotsMstTxns(
                        getOADBTransaction(), // トランザクション
                        params                // パラメータ
                        );
              
    // 更新処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    } 

    return XxcmnConstants.STRING_TRUE;
    
  }

  /***************************************************************************
   * (登録画面)OPMロットMSTのロック処理を行うメソッドです。
   * @param params パラメータ用HashMap
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void getOpmLotMstRowLock(
    HashMap params
  ) throws OAException 
  {

    String lotNo = (String)params.get("LotNo");

    Number itemId = (Number)params.get("ItemId");

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
      doRollBack();
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
        doRollBack();
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getOpmLotMstRowLock


  /***************************************************************************
   * (登録画面)OPMロットMST排他制御チェックを行うメソッドです。
   * @param params パラメータ用HashMap
   ***************************************************************************
   */
  public void chkOpmLotMstExclusiveControl(
    HashMap params
  )
  {
    String apiName  = "chkOpmLotMstExclusiveControl";
    //OAViewObject vo = null;
    //OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(ilm.lot_id) cnt "); // 発注ヘッダID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   IC_LOTS_MST ilm ");             // OPMロットマスタ
      sb.append("  WHERE  ilm.item_id = :2 ");            // 品目ID
      sb.append("  AND    ilm.LOT_NO  = :3 ");            // ロットNo
      sb.append("  AND    TO_CHAR(ilm.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
                
      // 発注ヘッダ情報
      //vo  = getXxpoSupplierResultsDetailsVO1();
      //int fetchedRowCount = vo.getFetchedRowCount();

      // 各種情報を取得します。
      Number itemId            = (Number)params.get("ItemId");            // 品目ID 
      String lotNum            = (String)params.get("LotNo");             // ロットNo
      String lotLastUpdateDate = (String)params.get("LotLastUpdateDate"); // 最終更新日

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
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkOpmLotMstExclusiveControl

  /***************************************************************************
   * (共通)コミット処理を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doCommit(
  ) throws OAException
  {
    // コミット
    getOADBTransaction().commit();
  } // doCommit

  /***************************************************************************
   * (登録画面)コンカレント：直送仕入・出荷実績作成処理です。
   * @return String - リターンコード
   ***************************************************************************
   */
  public String doDSResultsMake2()
  {

    // 仕入先出荷実績ヘッダーVO取得
    OAViewObject supplierResultsMakeHdrVO = getXxpoSupplierResultsMakeHdrVO1();

    OARow row = (OARow)supplierResultsMakeHdrVO.first();


    // 直送区分コード
    String dShipCode = (String)row.getAttribute("DropshipCode");

    // 支給No.
    String requestNumber = (String)row.getAttribute("RequestNumber");

    // 発注No
    String headerNumber = (String)row.getAttribute("HeaderNumber");

// 2008-12-16 v1.XXXX T.Yoshimoto Add Start 本番#689
    // 発注ヘッダID
    Number headerId     = (Number)row.getAttribute("HeaderId");
    
    // リターン
    String retFlag = XxcmnConstants.RETURN_NOT_EXE;
// 2008-12-16 v1.XXXX T.Yoshimoto Add Start 本番#689

    // 直送区分が『支給』(3)且つ、支給No.が取得できる場合のみ実行
    if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
      && !XxcmnUtility.isBlankOrNull(requestNumber)) 
    {
      HashMap params = new HashMap(3);

      params.put("DropShipCode",  dShipCode);
      params.put("RequestNumber", requestNumber);
      params.put("HeaderNumber",  headerNumber);

// 2008-12-16 v1.6 T.Yoshimoto Mod Start 本番#689
      //return XxpoUtility.doDropShipResultsMake(
      retFlag = XxpoUtility.doDropShipResultsMake(
                            getOADBTransaction(), // トランザクション
                            params                // パラメータ
                            );

      // コンカレント正常起動後、ステータスを金額確定へ変更
      if (XxcmnConstants.RETURN_SUCCESS.equals(retFlag)) 
      {
        XxpoUtility.updateStatusCode(
                      getOADBTransaction(),                        // トランザクション
                      XxpoConstants.STATUS_FINISH_DECISION_AMOUNT, // ステータス(数量確定)
                      headerId                                     // 発注ヘッダID
                      );
      }

      return retFlag;
// 2008-12-16 v1.XXXX T.Yoshimoto Mod Start 本番#689

    }

    return XxcmnConstants.RETURN_SUCCESS;
  } // doDSResultsMake2

  /***************************************************************************
   * (共通)ロールバック処理を行うメソッドです。
   ***************************************************************************
   */
  public void doRollBack()
  {
    // セーブポイントまでロールバックし、コミット
    XxpoUtility.rollBack(getOADBTransaction());
  } // doRollBack

  /***************************************************************************
   * (登録画面)ドリンク製品(換算単位あり)チェックを行うメソッドです。
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

// 2008-11-04 v1.4 D.Nihei Add Start 統合障害#104対応 
  /***************************************************************************
   * 納入日のコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyDeliveryDate()
  {
    // バッチヘッダ情報VO取得
    XxpoResultsSearchVOImpl vo = getXxpoResultsSearchVO1();
    OARow row                  = (OARow)vo.first();
    Date deliveryDateFrom      = (Date)row.getAttribute("DeliveryDateFrom"); // 納入日（開始）
    Date deliveryDateTo        = (Date)row.getAttribute("DeliveryDateTo");   // 納入日（終了）
    if (XxcmnUtility.isBlankOrNull(deliveryDateTo)) 
    {
      row.setAttribute("DeliveryDateTo", deliveryDateFrom);
    }
  } // copyDeliveryDate
// 2008-11-04 v1.4 D.Nihei Add End

  /**
   * 
   * Container's getter for XxpoResultsSearchVO1
   */
  public XxpoResultsSearchVOImpl getXxpoResultsSearchVO1()
  {
    return (XxpoResultsSearchVOImpl)findViewObject("XxpoResultsSearchVO1");
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


  /**
   * 
   * Container's getter for XxpoSupplierResultsMakePVO1
   */
  public XxpoSupplierResultsMakePVOImpl getXxpoSupplierResultsMakePVO1()
  {
    return (XxpoSupplierResultsMakePVOImpl)findViewObject("XxpoSupplierResultsMakePVO1");
  }


  /**
   * 
   * Container's getter for XxpoSupplierResultsTotalVO1
   */
  public XxpoSupplierResultsTotalVOImpl getXxpoSupplierResultsTotalVO1()
  {
    return (XxpoSupplierResultsTotalVOImpl)findViewObject("XxpoSupplierResultsTotalVO1");
  }


  /**
   * 
   * Container's getter for XxpoSupplierResultsMakeHdrVO1
   */
  public XxpoSupplierResultsMakeHdrVOImpl getXxpoSupplierResultsMakeHdrVO1()
  {
    return (XxpoSupplierResultsMakeHdrVOImpl)findViewObject("XxpoSupplierResultsMakeHdrVO1");
  }

  /**
   * 
   * Container's getter for XxpoSupplierResultsVO1
   */
  public XxpoSupplierResultsVOImpl getXxpoSupplierResultsVO1()
  {
    return (XxpoSupplierResultsVOImpl)findViewObject("XxpoSupplierResultsVO1");
  }

  /**
   * 
   * Container's getter for XxpoSupplierResultsDetailsVO1
   */
  public XxpoSupplierResultsDetailsVOImpl getXxpoSupplierResultsDetailsVO1()
  {
    return (XxpoSupplierResultsDetailsVOImpl)findViewObject("XxpoSupplierResultsDetailsVO1");
  }
  
}
