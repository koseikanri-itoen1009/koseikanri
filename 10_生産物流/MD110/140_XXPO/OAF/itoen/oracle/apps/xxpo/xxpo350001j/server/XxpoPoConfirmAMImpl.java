/*============================================================================
* ファイル名 : XxpoPoConfirmAMImpl
* 概要説明   : 発注確認画面:検索/発注・受入照会画面アプリケーションモジュール
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  伊藤ひとみ     新規作成
* 2008-05-07      伊藤ひとみ     内部変更要求対応(#41,48)
* 2009-02-24 1.1  二瓶　大輔     本番障害#6対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * 発注確認画面:検索/発注・受入照会画面アプリケーションモジュールです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.1
 ***************************************************************************
 */
public class XxpoPoConfirmAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoConfirmAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo350001j.server", "XxpoPoConfirmAMLocal");
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   ***************************************************************************
   */
  public void initialize()
  {
    // ************************* //
    // * 発注検索項目VO 初期化 * //
    // ************************* //
    OAViewObject poConfirmSearchVo = getXxpoPoConfirmSearchVO1();

    // 1行もない場合、
    if (!poConfirmSearchVo.isPreparedForExecution())
    {
      // 空行作成
      poConfirmSearchVo.setMaxFetchSize(0);
      poConfirmSearchVo.insertRow(poConfirmSearchVo.createRow());
      OARow poConfirmSearchRow = (OARow)poConfirmSearchVo.first();
      // キーに値をセット
      poConfirmSearchRow.setNewRowState(Row.STATUS_INITIALIZED);
      poConfirmSearchRow.setAttribute("RowKey", new Number(1));
    }
    // ************************* //
    // * ユーザー情報取得      * //
    // ************************* //
    getUserData();
  }

  /***************************************************************************
   * ユーザー情報を取得するメソッドです。
   ***************************************************************************
   */
  public void getUserData()
  {
    // ユーザー情報取得 
    HashMap retHashMap = XxpoUtility.getUserData(getOADBTransaction());                          

    // 発注検索項目VO取得
    OAViewObject poPoConfirmSearchVo = getXxpoPoConfirmSearchVO1();
    OARow poPoConfirmSearchRow = (OARow)poPoConfirmSearchVo.first();
    // 従業員区分をセット
    poPoConfirmSearchRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // 従業員区分
    // 従業員区分が2:外部の場合、仕入先・工場情報をセット
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      poPoConfirmSearchRow.setAttribute("OutSideUsrVendorId",    retHashMap.get("VendorId"));      // 取引先ID
      poPoConfirmSearchRow.setAttribute("OutSideUsrFactoryCode", retHashMap.get("FactoryCode")); // 工場コード
    }
  }

  /***************************************************************************
   * 必須チェックを行うメソッドです。
   ***************************************************************************
   */
  public void doRequiredCheck() throws OAException
  {

    // 発注検索項目VO取得
    OAViewObject poPoConfirmSearchVo = getXxpoPoConfirmSearchVO1();
    OARow poPoConfirmSearchRow = (OARow)poPoConfirmSearchVo.first();
    // 値を取得
    Object fdDate  = poPoConfirmSearchRow.getAttribute("DeliveryDateFrom"); // 納入日FROM

    // 納入日FROMがNULLの場合、エラー
// 2008-02-24 D.Nihei Add Start 本番障害#6対応
//    if (XxcmnUtility.isBlankOrNull(fdDate))
    // 発注No
    Object poNum  = poPoConfirmSearchRow.getAttribute("HeaderNumber");
    if (XxcmnUtility.isBlankOrNull(poNum) 
     && XxcmnUtility.isBlankOrNull(fdDate))
// 2008-02-24 D.Nihei Add End
    {
      throw new OAAttrValException(
                   OAAttrValException.TYP_VIEW_OBJECT,          
                   poPoConfirmSearchVo.getName(),
                   poPoConfirmSearchRow.getKey(),
                   "DeliveryDateFrom",
                   fdDate,
                   XxcmnConstants.APPL_XXPO,         
                   XxpoConstants.XXPO10002);
    }

  }

  /***************************************************************************
   * 検索処理を行うメソッドです。
   ***************************************************************************
   */
  public void doSearch()
  {
    // 発注検索項目VO取得
    OAViewObject poPoConfirmSearchVO = getXxpoPoConfirmSearchVO1();
    OARow poPoConfirmSearchRow = (OARow)poPoConfirmSearchVO.first();
    String peopleCode = (String)poPoConfirmSearchRow.getAttribute("PeopleCode");

    HashMap searchParams = new HashMap();
    
    // 検索パラメータに値をセット
    searchParams.put("peopleCode", peopleCode); // 従業員区分

    // 従業員区分が2:外部の場合、自取引ID・自工場IDを設定
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      searchParams.put("outSideUsrVendorId",    poPoConfirmSearchRow.getAttribute("OutSideUsrVendorId"));
      searchParams.put("outSideUsrFactoryCode", poPoConfirmSearchRow.getAttribute("OutSideUsrFactoryCode"));
    }

    searchParams.put("headerNumber",     poPoConfirmSearchRow.getAttribute("HeaderNumber"));        // 発注No.
    searchParams.put("vendorId",         poPoConfirmSearchRow.getAttribute("VendorId"));            // 取引先ID     
    searchParams.put("mediationId",      poPoConfirmSearchRow.getAttribute("MediationId"));         // 斡旋者ID
    searchParams.put("status",           poPoConfirmSearchRow.getAttribute("Status"));              // ステータス
    searchParams.put("location",         poPoConfirmSearchRow.getAttribute("Location"));            // 納品先コード
    searchParams.put("department",       poPoConfirmSearchRow.getAttribute("Department"));          // 発注部署コード
    searchParams.put("approved",         poPoConfirmSearchRow.getAttribute("Approved"));            // 承諾要
    searchParams.put("purchase",         poPoConfirmSearchRow.getAttribute("Purchase"));            // 直送区分
    searchParams.put("orderApproved",    poPoConfirmSearchRow.getAttribute("OrderApproved"));       // 発注承諾
    searchParams.put("cancelSearch",     poPoConfirmSearchRow.getAttribute("CancelSearch"));        // 取消検索
    searchParams.put("purchaseApproved", poPoConfirmSearchRow.getAttribute("PurchaseApproved"));    // 仕入承諾
    searchParams.put("peopleCode",       poPoConfirmSearchRow.getAttribute("PeopleCode"));          // 従業員区分
    searchParams.put("deliveryDateFrom", poPoConfirmSearchRow.getAttribute("DeliveryDateFrom"));    // 納入日FROM
    searchParams.put("deliveryDateTo",   poPoConfirmSearchRow.getAttribute("DeliveryDateTo"));      // 納入日TO
      
    // 検索実行
    XxpoPoConfirmVOImpl poConfirmVo = getXxpoPoConfirmVO1();
    poConfirmVo.initQuery(searchParams);

    OARow row = (OARow)poConfirmVo.first();
  }

  /***************************************************************************
   * 選択チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSelectCheck() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // 発注情報VO取得
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // 選択行のみ取得
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    
    // 選択チェック
    // 1行も選択されていない場合、エラー
    if (XxcmnUtility.isBlankOrNull(rows) || rows.length == 0)
    {
      // 未選択エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXPO, 
        XxpoConstants.XXPO10144);
    }
  }

  /***************************************************************************
   * 更新前チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doUpdateCheck() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // 発注情報VO取得
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // 選択行のみ取得
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    OARow row = null;
    
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      Date   deliveryDate = (Date)row.getAttribute("DeliveryDate"); // 納入日
      String statusCode   = (String)row.getAttribute("StatusCode"); // ステータス
      String statusDisp   = (String)row.getAttribute("StatusDisp"); // ステータス
        
      // 在庫クローズチェック　納入日が在庫クローズしている場合、エラー
      if (XxpoUtility.chkStockClose(
            getOADBTransaction(),  // トランザクション
            deliveryDate))         // 納入日
      {
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                poPoConfirmVo.getName(),
                row.getKey(),
                "DeliveryDate",
                deliveryDate,
                XxcmnConstants.APPL_XXPO, 
                XxpoConstants.XXPO10140));
      }

      // ステータスチェック　35:金額確定済み はエラー
      if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
      {
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                poPoConfirmVo.getName(),
                 row.getKey(),
                "StatusDisp",
                statusDisp,
                XxcmnConstants.APPL_XXPO, 
                XxpoConstants.XXPO10141));
      }

      // ステータスチェック　99:取消 はエラー
      if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
      {
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                poPoConfirmVo.getName(),
                row.getKey(),
                "StatusDisp",
                statusDisp,
                XxcmnConstants.APPL_XXPO, 
                XxpoConstants.XXPO10142));
      }
    }

    // エラーがある場合、インラインメッセージ出力
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  }

  /***************************************************************************
   * ロック・排他処理を行うメソッドです。
   * @param  vo  OAViewObject
   * @param  row OARow
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getLock(
    OAViewObject vo,
    OARow        row
  ) throws OAException
  { 
    Number xxpoHeaderId   = (Number)row.getAttribute("XxpoHeaderId");  // 発注ヘッダアドオンID
    String lastUpdateDate = (String)row.getAttribute("LastUpdateDate");// 最終更新日
    String headerNumber   = (String)row.getAttribute("HeaderNumber");  // 発注番号
        
    // 発注ヘッダアドオンロック取得・排他チェック
    String retFlag = XxpoUtility.getXxpoPoHeadersAllLock(
                      getOADBTransaction(), // トランザクション
                      xxpoHeaderId,         // 発注ヘッダアドオンID
                      lastUpdateDate);      // 最終更新日

    // ロックエラーの場合
    if (XxcmnConstants.RETURN_ERR1.equals(retFlag))
    {
      // ロックエラーインラインメッセージ出力
      throw new OAAttrValException(
                   OAAttrValException.TYP_VIEW_OBJECT,          
                   vo.getName(),
                   row.getKey(),
                   "HeaderNumber",
                   headerNumber,
                   XxcmnConstants.APPL_XXPO, 
                   XxpoConstants.XXPO10138);

    // 排他エラーの場合
    } else if (XxcmnConstants.RETURN_ERR2.equals(retFlag))
    {
      // 排他エラーインラインメッセージ出力
      throw new OAAttrValException(
                   OAAttrValException.TYP_VIEW_OBJECT,          
                   vo.getName(),
                   row.getKey(),
                   "HeaderNumber",
                   headerNumber,
                   XxcmnConstants.APPL_XXCMN, 
                   XxcmnConstants.XXCMN10147);
    }
  }
  /***************************************************************************
   * 発注承認処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doOrderApproving() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    
    // 発注情報VO取得
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // 選択行のみ取得
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    OARow row = null;
      
    // 選択行全件LOOP
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      Number xxpoHeaderId   = (Number)row.getAttribute("XxpoHeaderId");  // 発注ヘッダアドオンID
        
      // 発注承諾フラグがY以外の場合、発注承諾を行う。
      if (XxcmnConstants.STRING_Y.equals(row.getAttribute("OrderApprovedFlag")) == false)
      {
        // 発注ヘッダアドオンロック取得・排他チェック
        getLock(poPoConfirmVo, row);

        // 発注承認処理
        String retFlag = XxpoUtility.doOrderApproving(
                    getOADBTransaction(), // トランザクション
                    xxpoHeaderId);        // 発注ヘッダアドオンID

      }
    }
    // 全件正常終了の場合、コミット
    XxpoUtility.commit(getOADBTransaction());
  }

  /***************************************************************************
   * 仕入承認処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doPurchaseApproving() throws OAException
  {
    String retFlag = null;
    
    // 発注情報VO取得
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // 選択行のみ取得
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    OARow row = null;
      
    // 選択行全件LOOP
    for (int i = 0; i < rows.length; i++)
    {
      // i番目の行を取得
      row = (OARow)rows[i];
      Number xxpoHeaderId   = (Number)row.getAttribute("XxpoHeaderId");  // 発注ヘッダアドオンID
        
      // 仕入承諾フラグがY以外の場合、仕入承諾を行う。
      if (XxcmnConstants.STRING_Y.equals(row.getAttribute("PurchaseApprovedFlag")) == false)
      {
        // 発注ヘッダアドオンロック取得・排他チェック
        getLock(poPoConfirmVo, row);

        // 仕入承認処理
        retFlag = XxpoUtility.doPurchaseApproving(
                    getOADBTransaction(), // トランザクション
                    xxpoHeaderId);        // 発注ヘッダアドオンID

      }
    }
    // 全件正常終了の場合、コミット
    XxpoUtility.commit(getOADBTransaction());
  }

  /***************************************************************************
   * ページングの際にチェックボックスをOFFにします。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void checkBoxOff() throws OAException
  {
    // 発注情報VO取得
    OAViewObject vo = getXxpoPoConfirmVO1();
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
   * 発注・受入照会画面の初期化処理を行うメソッドです。
   ***************************************************************************
   */
  public void initialize2()
  {
    // 発注・受入情報VO取得
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1行もない場合、初期化
    if (!poPoInquiryVo.isPreparedForExecution())
    {
      poPoInquiryVo.setWhereClauseParam(0,null);
      poPoInquiryVo.executeQuery();
      poPoInquiryVo.insertRow(poPoInquiryVo.createRow());
      // 1行目を取得
      OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();
      // キーに値をセット
      poPoInquiryRow.setNewRowState(Row.STATUS_INITIALIZED);
      poPoInquiryRow.setAttribute("HeaderId", new Number(-1));
    }

    // 合計タブVO取得
    OAViewObject sumVo = getXxpoPoInquirySumVO1();
    // 1行もない場合、初期化
    if (!sumVo.isPreparedForExecution())
    {
      sumVo.setWhereClauseParam(0,null);
      sumVo.setWhereClauseParam(1,null);
      sumVo.setWhereClauseParam(2,null);
      sumVo.setWhereClauseParam(3,null);
      sumVo.setWhereClauseParam(4,null);
      sumVo.executeQuery();
      sumVo.insertRow(sumVo.createRow());
      // 1行目を取得
      OARow sumRow = (OARow)sumVo.first();
      // キーに値をセット
      sumRow.setNewRowState(Row.STATUS_INITIALIZED);
      sumRow.setAttribute("RowKey", new Number(-1));
    }

    // 発注・受入PVO取得
    OAViewObject poPoInquiryPvo = getXxpoPoInquiryPVO1();      
    // 1行もない場合、、初期化
    if (!poPoInquiryPvo.isPreparedForExecution())
    {    
      poPoInquiryPvo.setMaxFetchSize(0);
      poPoInquiryPvo.executeQuery();
      poPoInquiryPvo.insertRow(poPoInquiryPvo.createRow());
      // 1行目を取得
      OARow poPoInquiryPvoRow = (OARow)poPoInquiryPvo.first();
      // キーに値をセット
      poPoInquiryPvoRow.setAttribute("RowKey", new Number(1));
    }    
  }

  /***************************************************************************
   * 発注・受入照会画面の検索処理を行うメソッドです。
   * @param searchHeaderId - 検索パラメータ
   ***************************************************************************
   */
  public void doSearch(String searchHeaderId)
  {
    // ヘッダ検索実行
    XxpoPoInquiryVOImpl poPoInquiryVo = getXxpoPoInquiryVO1();
    poPoInquiryVo.initQuery(searchHeaderId);
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();
    // ヘッダデータを取得できなかった場合
    if (poPoInquiryVo.getRowCount() == 0)
    {
      // VO初期化
      poPoInquiryVo.setWhereClauseParam(0,null);
      poPoInquiryVo.executeQuery();
      poPoInquiryVo.insertRow(poPoInquiryVo.createRow());
      // 1行目を取得
      poPoInquiryRow = (OARow)poPoInquiryVo.first();
      // キーに値をセット
      poPoInquiryRow.setNewRowState(Row.STATUS_INITIALIZED);
      poPoInquiryRow.setAttribute("HeaderId", new Number(-1));

      // 無効切替処理
      disabledChanged("1"); 
      
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);      
    }

    Date deliveryDate  = (Date)poPoInquiryRow.getAttribute("DeliveryDate"); // 納入日
    String statusCode  = (String)poPoInquiryRow.getAttribute("StatusCode"); // ステータス

    // 明細検索実行
    XxpoPoInquiryLineVOImpl lineVo = getXxpoPoInquiryLineVO1();
    lineVo.initQuery(
      statusCode,
      deliveryDate,
      searchHeaderId);
    OARow lineRow = (OARow)lineVo.first();
    // 明細データを取得できなかった場合
    if (lineVo.getRowCount() == 0)
    {
      // 無効切替処理
      disabledChanged("1"); 
      
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);      
    }

    // 合計タブ検索実行
    XxpoPoInquirySumVOImpl sumVo = getXxpoPoInquirySumVO1();
    sumVo.initQuery(
      statusCode,
      searchHeaderId
    ); 
    OARow SumRow = (OARow)sumVo.first();
    // 合計タブデータを取得できなかった場合
    if (sumVo.getRowCount() == 0)
    {
      sumVo.setWhereClauseParam(0,null);
      sumVo.setWhereClauseParam(1,null);
      sumVo.setWhereClauseParam(2,null);
      sumVo.setWhereClauseParam(3,null);
      sumVo.setWhereClauseParam(4,null);
      sumVo.executeQuery();
      sumVo.insertRow(sumVo.createRow());
      // 1行目を取得
      OARow sumRow = (OARow)sumVo.first();
      // キーに値をセット
      sumRow.setNewRowState(Row.STATUS_INITIALIZED);
      sumRow.setAttribute("RowKey", new Number(-1));
      
      // 無効切替処理
      disabledChanged("1"); 
      
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);      
    }
    // 無効切替処理
    disabledChanged("0"); // 有効 
  }

  /***************************************************************************
   * 無効切替制御を行うメソッドです。
   * param flag - 0:有効
   *            - 1:無効
   ***************************************************************************
   */
  public void disabledChanged(
    String flag
  )
  {
    // 発注・受入PVO取得
    OAViewObject poPoInquiryPvo = getXxpoPoInquiryPVO1();    
    // 1行目を取得
    OARow disabledRow = (OARow)poPoInquiryPvo.first();

    // フラグが0:有効の場合
    if ("0".equals(flag))
    {
      disabledRow.setAttribute("OrderApprovingDisabled",    Boolean.FALSE); // 発注承諾ボタン押下可
      disabledRow.setAttribute("PurchaseApprovingDisabled", Boolean.FALSE); // 仕入承諾ボタン押下可
    
    // フラグが1:無効の場合
    } else if ("1".equals(flag))
    {
      disabledRow.setAttribute("OrderApprovingDisabled",    Boolean.TRUE); // 発注承諾ボタン押下不可
      disabledRow.setAttribute("PurchaseApprovingDisabled", Boolean.TRUE); // 仕入承諾ボタン押下不可

    }
  }
  
  /***************************************************************************
   * 発注受入照会画面の更新前チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doUpdateCheck2() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // 発注受入照会ヘッダ情報VO取得
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1行目を取得
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();    

    Date   deliveryDate = (Date)poPoInquiryRow.getAttribute("DeliveryDate"); // 納入日
    String statusCode   = (String)poPoInquiryRow.getAttribute("StatusCode"); // ステータス
    String statusDisp   = (String)poPoInquiryRow.getAttribute("StatusDisp"); // ステータス
        
    // 在庫クローズチェック　納入日が在庫クローズしている場合、エラー
    if (XxpoUtility.chkStockClose(
          getOADBTransaction(),  // トランザクション
          deliveryDate))         // 納入日
    {
      exceptions.add( 
        new OAAttrValException(
              OAAttrValException.TYP_VIEW_OBJECT,          
              poPoInquiryVo.getName(),
              poPoInquiryRow.getKey(),
              "DeliveryDate",
              deliveryDate,
              XxcmnConstants.APPL_XXPO, 
              XxpoConstants.XXPO10140));
    }

    // ステータスチェック　35:金額確定済み はエラー
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      exceptions.add( 
        new OAAttrValException(
              OAAttrValException.TYP_VIEW_OBJECT,          
              poPoInquiryVo.getName(),
              poPoInquiryRow.getKey(),
              "StatusDisp",
              statusDisp,
              XxcmnConstants.APPL_XXPO, 
              XxpoConstants.XXPO10141));
    }

    // ステータスチェック　99:取消 はエラー
    if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
    {
      exceptions.add( 
        new OAAttrValException(
              OAAttrValException.TYP_VIEW_OBJECT,          
              poPoInquiryVo.getName(),
              poPoInquiryRow.getKey(),
              "StatusDisp",
              statusDisp,
              XxcmnConstants.APPL_XXPO, 
              XxpoConstants.XXPO10142));
    }

    // エラーがある場合、インラインメッセージ出力
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  }

  /***************************************************************************
   * 発注受入照会画面の発注承認処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doOrderApproving2() throws OAException
  {
    String retFlag = null;
    // 発注受入照会ヘッダ情報VO取得
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1行目を取得
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();      
    Number xxpoHeaderId   = (Number)poPoInquiryRow.getAttribute("XxpoHeaderId");  // 発注ヘッダアドオンID
    String lastUpdateDate = (String)poPoInquiryRow.getAttribute("LastUpdateDate");// 最終更新日
        
    // 発注承諾フラグがY以外の場合、発注承諾を行う。
    if (XxcmnConstants.STRING_Y.equals(poPoInquiryRow.getAttribute("OrderApprovedFlag")) == false)
    {

      // 発注ヘッダアドオンロック取得・排他チェック
      retFlag = XxpoUtility.getXxpoPoHeadersAllLock(
                  getOADBTransaction(), // トランザクション
                  xxpoHeaderId,         // 発注ヘッダアドオンID
                  lastUpdateDate);      // 最終更新日

      // ロックエラーの場合
      if (XxcmnConstants.RETURN_ERR1.equals(retFlag))
      {
        // ロックエラーメッセージ出力
        throw new OAException(
                     XxcmnConstants.APPL_XXPO, 
                     XxpoConstants.XXPO10138);

     // 排他エラーの場合
      } else if (XxcmnConstants.RETURN_ERR2.equals(retFlag))
      {
        // 排他エラーメッセージ出力
        throw new OAException(
           XxcmnConstants.APPL_XXCMN, 
           XxcmnConstants.XXCMN10147);
      }
 
      // 発注承認処理
      retFlag = XxpoUtility.doOrderApproving(
                  getOADBTransaction(), // トランザクション
                  xxpoHeaderId);        // 発注ヘッダアドオンID

    }
    // 全件正常終了の場合、コミット
    XxpoUtility.commit(getOADBTransaction());

  }  

  /***************************************************************************
   * 発注受入照会画面の仕入承認処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doPurchaseApproving2() throws OAException
  {
    String retFlag = null;
    // 発注受入照会ヘッダ情報VO取得
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1行目を取得
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();      
    Number xxpoHeaderId   = (Number)poPoInquiryRow.getAttribute("XxpoHeaderId");  // 発注ヘッダアドオンID
    String lastUpdateDate = (String)poPoInquiryRow.getAttribute("LastUpdateDate");// 最終更新日
        
    // 仕入承諾フラグがY以外の場合、仕入承諾を行う。
    if (XxcmnConstants.STRING_Y.equals(poPoInquiryRow.getAttribute("PurchaseApprovedFlag")) == false)
    {

      // 発注ヘッダアドオンロック取得・排他チェック
      retFlag = XxpoUtility.getXxpoPoHeadersAllLock(
                  getOADBTransaction(), // トランザクション
                  xxpoHeaderId,         // 発注ヘッダアドオンID
                  lastUpdateDate);      // 最終更新日

      // ロックエラーの場合
      if (XxcmnConstants.RETURN_ERR1.equals(retFlag))
      {
        // ロックエラーメッセージ出力
        throw new OAException(
                     XxcmnConstants.APPL_XXPO, 
                     XxpoConstants.XXPO10138);

     // 排他エラーの場合
      } else if (XxcmnConstants.RETURN_ERR2.equals(retFlag))
      {
        // 排他エラーメッセージ出力
        throw new OAException(
           XxcmnConstants.APPL_XXCMN, 
           XxcmnConstants.XXCMN10147);
      }
 
      // 仕入承認処理
      retFlag = XxpoUtility.doPurchaseApproving(
                  getOADBTransaction(), // トランザクション
                  xxpoHeaderId);        // 発注ヘッダアドオンID

    }
    // 全件正常終了の場合、コミット
    XxpoUtility.commit(getOADBTransaction());

  }  

// 2008-02-24 D.Nihei Add Start 本番障害#6対応
  /***************************************************************************
   * 納入日のコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyDeliveryDate()
  {
    // バッチヘッダ情報VO取得
    XxpoPoConfirmSearchVOImpl vo = getXxpoPoConfirmSearchVO1();
    OARow row = (OARow)vo.first();
    // 値を取得
    Date deliveryDateFrom      = (Date)row.getAttribute("DeliveryDateFrom"); // 納入日（開始）
    Date deliveryDateTo        = (Date)row.getAttribute("DeliveryDateTo");   // 納入日（終了）
    if (XxcmnUtility.isBlankOrNull(deliveryDateTo)) 
    {
      row.setAttribute("DeliveryDateTo", deliveryDateFrom);
    }
  } // copyDeliveryDate
// 2008-02-24 D.Nihei Add End

  /**
   * 
   * Container's getter for XxpoPoConfirmSearchVO1
   */
  public XxpoPoConfirmSearchVOImpl getXxpoPoConfirmSearchVO1()
  {
    return (XxpoPoConfirmSearchVOImpl)findViewObject("XxpoPoConfirmSearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoConfirmVO1
   */
  public XxpoPoConfirmVOImpl getXxpoPoConfirmVO1()
  {
    return (XxpoPoConfirmVOImpl)findViewObject("XxpoPoConfirmVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquiryVO1
   */
  public XxpoPoInquiryVOImpl getXxpoPoInquiryVO1()
  {
    return (XxpoPoInquiryVOImpl)findViewObject("XxpoPoInquiryVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquirySumVO1
   */
  public XxpoPoInquirySumVOImpl getXxpoPoInquirySumVO1()
  {
    return (XxpoPoInquirySumVOImpl)findViewObject("XxpoPoInquirySumVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquiryPVO1
   */
  public XxpoPoInquiryPVOImpl getXxpoPoInquiryPVO1()
  {
    return (XxpoPoInquiryPVOImpl)findViewObject("XxpoPoInquiryPVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquiryLineVO1
   */
  public XxpoPoInquiryLineVOImpl getXxpoPoInquiryLineVO1()
  {
    return (XxpoPoInquiryLineVOImpl)findViewObject("XxpoPoInquiryLineVO1");
  }
}