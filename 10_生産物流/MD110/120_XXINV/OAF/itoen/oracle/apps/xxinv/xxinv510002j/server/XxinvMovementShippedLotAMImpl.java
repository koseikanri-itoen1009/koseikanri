/*============================================================================
* ファイル名 : XxinvMovementShippedLotAMImpl
* 概要説明   : 出庫・入庫ロット明細画面アプリケーションモジュール
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  伊藤ひとみ     新規作成
* 2008-07-10 1.1  伊藤ひとみ     内部変更 自身のコンカレントコールで変更した場合、排他エラーとしない。
* 2008-07-14 1.2  山本  恭久     内部変更 重量容積小口個数関数のコールタイミングの変更
* 2008-10-21 1.3  伊藤ひとみ     統合テスト 指摘353対応
* 2009-12-28 1.4  伊藤ひとみ     本稼動障害#695
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;
import itoen.oracle.apps.xxinv.util.XxinvUtility;

import java.sql.SQLException;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * 出庫ロット明細画面アプリケーションモジュールです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.4
 ***************************************************************************
 */
public class XxinvMovementShippedLotAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementShippedLotAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxinv.xxinv510002j.server", "XxinvMovementShippedLotAMLocal");
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   * @param params - パラメータ
   ***************************************************************************
   */
  public void initialize(HashMap params)
  {
    // *********************** //
    // *    PVO 初期化       * //
    // *********************** //
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();   
    // 1行もない場合、空行作成
    if (!pvo.isPreparedForExecution())
    {    
      // 1行もない場合、空行作成
      pvo.setMaxFetchSize(0);
      pvo.executeQuery();
      pvo.insertRow(pvo.createRow());
      // 1行目を取得
      OARow pvoRow = (OARow)pvo.first();
      // キーに値をセット
      pvoRow.setAttribute("RowKey", new Number(1));
    }    

    // *********************** //
    // *   表示データ取得    * //
    // *********************** //
    doSearch(params);
    
    // *********************** //
    // *      項目制御       * //
    // *********************** //
    itemControl(XxcmnConstants.STRING_N);
  }

  /***************************************************************************
   * 検索処理を行うメソッドです。
   * @param params       - パラメータ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearch(HashMap params) throws OAException
  {
    // パラメータ取得
    String movLineId        = (String)params.get("movLineId");      // 移動明細ID
    String productFlg       = (String)params.get("productFlg");     // 製品識別区分
    String documentTypeCode = XxinvConstants.DOC_TYPE_MOVE;         // 文書タイプ 20:移動
    String recordTypeCode   = (String)params.get("recordTypeCode"); // レコードタイプ 20:出庫実績 30:入庫実績
    String updateFlag       = (String)params.get("updateFlag");

    // ********************** //    
    // *   明細検索         * //
    // ********************** //
    XxinvLineVOImpl lineVo = getXxinvLineVO1();
    lineVo.initQuery(
      movLineId,
      productFlg);
      
    // 明細を取得できなかった場合
    if (lineVo.getRowCount() == 0)
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500); 
    } 
    // 1行目を取得
    OARow lineRow = (OARow)lineVo.first();
    // パラメータをセット
    lineRow.setAttribute("ProductFlg",        productFlg);        // 製品識別区分
    lineRow.setAttribute("DocumentTypeCode",  documentTypeCode);  // 文書タイプ
    lineRow.setAttribute("RecordTypeCode",    recordTypeCode);    // レコードタイプ
    lineRow.setAttribute("UpdateFlag",    updateFlag);
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");     // ロット管理区分
    Number numOfCases = (Number)lineRow.getAttribute("NumOfCases"); // ケース入数

    // ********************** //    
    // *   指示ロット検索   * //
    // ********************** //
    XxinvIndicateLotVOImpl indicateLotVo = getXxinvIndicateLotVO1();
    indicateLotVo.initQuery(movLineId, productFlg, lotCtl, numOfCases);
    // 1行目を取得
    OARow indicateLotRow = (OARow)indicateLotVo.first();

    // ********************** //    
    // *   実績ロット検索   * //
    // ********************** //
    XxinvResultLotVOImpl resultLotVo = getXxinvResultLotVO1();
    resultLotVo.initQuery(
      movLineId,
      productFlg,
      recordTypeCode,
      lotCtl,
      numOfCases);
    OARow resultLotRow = (OARow)resultLotVo.first();

    // 実績ロットを取得できなかった場合、指示ロットを検索
    if (resultLotVo.getRowCount() == 0)
    {
      resultLotVo.initQuery(
        movLineId,
        productFlg,
        XxinvConstants.RECORD_TYPE_10,
        lotCtl,
        numOfCases);
      resultLotRow = (OARow)resultLotVo.first();
    } else
    {
      // PVO取得
      OAViewObject pvo = getXxInvMovementShippedLotPVO1();
      // PVO1行目を取得
      OARow pvoRow = (OARow)pvo.first();
      // ロット逆転チェック不要フラグ設定
      pvoRow.setAttribute("lotRevNotExe", "1");
    }

    // 取得できなかった場合、デフォルトで1行表示する。
    if (resultLotVo.getRowCount() == 0)
    {
      addRow();
    }
  }

  /***************************************************************************
   * 項目制御を行うメソッドです。
   * @param  errFlag   - Y:エラーの場合(戻るボタン以外不能)  N:正常
   ***************************************************************************
   */
  public void itemControl(String errFlag)
  {
    // PVO取得
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();   
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // デフォルト値設定
    pvoRow.setAttribute("CheckRendered",           Boolean.TRUE);  // チェック：表示
    pvoRow.setAttribute("AddRowRendered",          Boolean.TRUE);  // 行挿入：表示
    pvoRow.setAttribute("ReturnDisabled",          Boolean.FALSE); // 取消：有効
    pvoRow.setAttribute("GoDisabled",              Boolean.FALSE); // 適用：有効
    pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.FALSE); // 数量：有効

    // エラーの場合(戻るボタン以外制御不能)
    if (XxcmnConstants.STRING_Y.equals(errFlag))
    {
      pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // チェック：非表示
      pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // 行挿入：非表示
      pvoRow.setAttribute("ReturnDisabled",          Boolean.TRUE);  // 取消：無効
      pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // 適用：無効
      pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // 数量：無効

    // エラーでない場合      
    } else
    {
      // 明細VO取得
      OAViewObject lineVo = getXxinvLineVO1();
      // 明細1行目を取得
      OARow lineRow   = (OARow)lineVo.first();
      String lotCtl   = (String)lineRow.getAttribute("LotCtl"); // ロット管理区分
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
      String compActualFlg     = (String)lineRow.getAttribute("CompActualFlg");   // 実績計上済フラグ
      Date   actualShipDate    = (Date)lineRow.getAttribute("ActualShipDate");    // 出庫実績日
      Date   actualArrivalDate = (Date)lineRow.getAttribute("ActualArrivalDate"); // 入庫実績日
// 2008-10-21 H.Itou Add End

      // ロット管理外品の場合
      if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
      {
        pvoRow.setAttribute("CheckRendered",  Boolean.FALSE); // チェック：非表示
        pvoRow.setAttribute("AddRowRendered", Boolean.FALSE); // 行挿入：非表示
      }

// 2008-10-21 H.Itou Add Start 統合テスト指摘353
      // 実績計上済で出庫実績日がクローズしている場合
      if  (XxcmnConstants.STRING_Y.equals(compActualFlg)
        && XxinvUtility.chkStockClose(getOADBTransaction(), actualShipDate))
      {
        // 変更不可なので参照のみ。
        pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // チェック：非表示
        pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // 行挿入：非表示
        pvoRow.setAttribute("ReturnDisabled",          Boolean.FALSE); // 取消：有効
        pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // 適用：無効
        pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // 数量：無効
      }
// 2008-10-21 H.Itou Add End
    }
 }  
 
  /***************************************************************************
   * 行挿入処理を行うメソッドです。
   ***************************************************************************
   */
  public void addRow()
  {
    // 明細VO取得
    OAViewObject lineVo = getXxinvLineVO1();
    // 1行目を取得
    OARow lineRow   = (OARow)lineVo.first();
    String productFlg = (String)lineRow.getAttribute("ProductFlg"); // 製品識別区分
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");     // ロット管理区分
      
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    // ROW取得
    OARow resultLotRow = (OARow)resultLotVo.createRow();

    // ロット管理外品の場合
    if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
    {
      // Switcherの制御
      resultLotRow.setAttribute("LotNoSwitcher" ,            "LotNoDisabled");           // ロットNo：入力不可
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// 製造年月日：入力不可
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // 賞味期限：入力不可
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // 固有記号：入力不可

      // デフォルト値の設定
      resultLotRow.setAttribute("LotId", XxinvConstants.DEFAULT_LOT);    // ロットID

    // 製品識別区分が1:製品の場合
    } else if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
    {
      // Switcherの制御
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoDisabled");          // ロットNo：入力不可
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateEnabled");// 製造年月日：入力可
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateEnabled");       // 賞味期限：入力可
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeEnabled");        // 固有記号：入力可

    // 製品識別区分が2:製品以外の場合
    } else
    {
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoEnabled");            // ロットNo：入力可
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// 製造年月日：入力不可
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // 賞味期限：入力不可
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // 固有記号：入力不可      
    }
    // 移動ロット詳細の新規ID取得
    Number movLotDtlId = XxinvUtility.getMovLotDtlId(getOADBTransaction());
    
    // デフォルト値の設定
    resultLotRow.setAttribute("MovLotDtlId", movLotDtlId);             // 移動ロット詳細ID
    resultLotRow.setAttribute("NewRow",      XxcmnConstants.STRING_Y); // 新規行フラグ   

    // 新規行挿入
    resultLotVo.last();
    resultLotVo.next();
    resultLotVo.insertRow(resultLotRow);
    resultLotRow.setNewRowState(Row.STATUS_INITIALIZED);
  } // addRow

  /***************************************************************************
   * チェックボタン押下処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void checkLot() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);

    String apiName   = "checkLot";
    
    // 明細VO取得
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    String productFlg = (String)lineRow.getAttribute("ProductFlg" ); // 製品識別区分
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");      // ロット管理区分
    Number itemId     = (Number)lineRow.getAttribute("ItemId");      // 品目ID
      
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;
    // 1行目
    resultLotVo.first();

    // ロット管理区分が1：ロット管理品の場合のみチェックを行う。
    if (XxinvConstants.LOT_CTL_Y.equals(lotCtl))
    {
      // 全件ループ
      while (resultLotVo.getCurrentRow() != null)
      {
        // 処理対象行を取得
        resultLotRow = (OARow)resultLotVo.getCurrentRow();

        // ********************************** // 
        // *   チェック実施レコード判定     * //
        // ********************************** //
        // 製品識別区分が1:製品の場合
        if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
        {
          // 新規行の場合、表示項目(ロットNo)をリセット
          if (XxcmnConstants.STRING_Y.equals(resultLotRow.getAttribute("NewRow")))
          {
            resultLotRow.setAttribute("LotNo", "");
          }
            
          // 製造年月日、賞味期限、固有記号すべてに入力のない場合、チェックを行わない。
          if (XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("ManufacturedDate"))
            && XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("UseByDate"))
            && XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("KoyuCode")))
          {
            // 処理を行わずに、次のレコード処理
            resultLotVo.next();
            continue;
          }
          
        // 製品以外の場合
        } else
        {
           // 新規行の場合、表示項目(製造年月日、賞味期限、固有記号)をリセット
          if (XxcmnConstants.STRING_Y.equals(resultLotRow.getAttribute("NewRow")))
          {
            resultLotRow.setAttribute("ManufacturedDate", "");
            resultLotRow.setAttribute("UseByDate", "");
            resultLotRow.setAttribute("KoyuCode", "");
          }
          
          // ロットNoに入力のない場合、チェックを行わない。
          if (XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("LotNo")))
          {
            // 処理を行わずに、次のレコード処理
            resultLotVo.next();
            continue;
          }
        }

        // ********************************** // 
        // *   ロットマスタ妥当性チェック   * //
        // ********************************** //
        String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ロットNo
        Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // 製造年月日
        Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // 賞味期限
        String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // 固有記号
        String movInstRel       = null;
        String statusDesc       = null;
        String retCode          = null;
        Number lotId            = null;
        String stock_quantity   = null;
        HashMap ret = XxinvUtility.seachOpmLotMst(
                        getOADBTransaction(),
                        lotNo,
                        manufacturedDate,
                        useByDate,
                        koyuCode,
                        itemId,
                        productFlg);

        // 戻り値データを取得
        lotNo            = (String)ret.get("lotNo");      // ロットNo
        manufacturedDate = null;                          // 製造年月日
        useByDate        = null;                          // 賞味期限
        koyuCode         = (String)ret.get("koyuCode");   // 固有記号
        retCode          = (String)ret.get("retCode");    // 戻り値
        lotId            = (Number)ret.get("lotId");      // ロットID
        movInstRel       = (String)ret.get("movInstRel"); // 移動指示(実績)
        statusDesc       = (String)ret.get("statusDesc"); // ステータスコード名称
        stock_quantity   = (String)ret.get("stock_quantity"); // 在庫入数
 
        try
        {
          if (!XxcmnUtility.isBlankOrNull(ret.get("manufacturedDate")))
          {
            manufacturedDate = new Date(ret.get("manufacturedDate")); // 製造年月日          
          }
          if (!XxcmnUtility.isBlankOrNull(ret.get("useByDate")))
          {
            useByDate = new Date(ret.get("useByDate")); // 賞味期限          
          }

        // SQL例外の場合
        } catch(SQLException s)
        {
          // ロールバック
          XxinvUtility.rollBack(getOADBTransaction());
          // ログ出力
          XxcmnUtility.writeLog(
            getOADBTransaction(),
            XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
            s.toString(),
            6);
          // エラーメッセージ出力
          throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10123);
        }

        // 戻り値が0：異常の場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          // ロット情報取得エラー
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "LotNo",
                  (String)resultLotRow.getAttribute("LotNo"),
                  XxcmnConstants.APPL_XXINV, 
                  XxinvConstants.XXINV10033));
                
          // 後続処理を行わずに、次のレコード処理
          resultLotVo.next();
          continue;
        }

        // ********************************** // 
        // *   ロットステータスチェック     * //
        // ********************************** //
        String actualQuantity = (String)resultLotRow.getAttribute("ConvertQuantity"); // 換算数量
        double actualQuantityD = 0;
        // 数量が入力されている場合は、数量をdouble型に変換
        if (!XxcmnUtility.isBlankOrNull(actualQuantity))
        {
          actualQuantityD = Double.parseDouble(actualQuantity);// 換算実績数量                    
        }
        // 換算数量に値のない場合または、換算実績数量が0でない場合はロットステータスチェックを行う。
        if (XxcmnUtility.isBlankOrNull(actualQuantity) || (actualQuantityD != 0))
        {
          // 移動指示(実績)がN:対象外の場合
          if (XxcmnConstants.STRING_N.equals(movInstRel))
          {
            // ロットステータスエラー
            // エラーメッセージトークン取得
            MessageToken[] tokens = {new MessageToken(XxinvConstants.TOKEN_LOT_STATUS, statusDesc)};
            // エラーメッセージ取得                            
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10165,
                    tokens));

            // 後続処理を行わずに、次のレコード処理
            resultLotVo.next();
            continue;
          }
        }

        // ********************************** // 
        // *   ロットデータをROWにセット    * //
        // ********************************** //
        resultLotRow.setAttribute("LotNo",            lotNo);            // ロットNo
        resultLotRow.setAttribute("ManufacturedDate", manufacturedDate); // 製造年月日
        resultLotRow.setAttribute("UseByDate",        useByDate);        // 賞味期限
        resultLotRow.setAttribute("KoyuCode",         koyuCode);         // 固有記号
        resultLotRow.setAttribute("LotId",            lotId);            // ロットID
        resultLotRow.setAttribute("StockQuantity",    stock_quantity);   // 在庫入数

        // 次のレコードへ
        resultLotVo.next();
      }

      // ********************************** // 
      // *   ロットNo重複チェック         * //
      // ********************************** //
      // 1行目
      resultLotVo.first();
      // 全件ループ
      while (resultLotVo.getCurrentRow() != null)
      {
        resultLotRow = (OARow)resultLotVo.getCurrentRow();
        // 値取得
        String lotNo = (String)resultLotRow.getAttribute("LotNo"); // ロットNo

        // ロットNoに値がある場合のみ重複チェック
        // ロットNoのNULLは重複としない
        if (!XxcmnUtility.isBlankOrNull(lotNo))
        {
          // ロットNoの一致する行を取得
          OAViewObject vo  = getXxinvResultLotVO1();
          Row[] rows = vo.getFilteredRows("LotNo", lotNo);
          OARow row = null;
          // 2行以上ある場合は、重複しているのでエラー
          if (rows.length > 1)
          { 
            // 重複エラーメッセージ取得                          
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10129));
                  
          }          
        }
        // 次のレコードへ
        resultLotVo.next();
      }
   
      // エラーがある場合、インラインメッセージ出力
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
  }

  /***************************************************************************
   * エラーチェックを行うメソッドです。
   * @return String    正常:TRUE、異常:FALSE
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String checkError() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    HashMap date = new HashMap();
    String ret = XxcmnConstants.STRING_TRUE;
    int i = 0;

    // 明細VO取得
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    String productFlg = (String)lineRow.getAttribute("ProductFlg" ); // 製品識別区分
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");      // ロット管理区分

    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;
    // 1行目
    resultLotVo.first();

    // ************************* //
    // *   必須チェック        * //
    // ************************* //    
    // 全件ループ
    while (resultLotVo.getCurrentRow() != null)
    {
      // 処理対象行を取得
      resultLotRow = (OARow)resultLotVo.getCurrentRow();
      String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ロットNo
      Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // 製造年月日
      Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // 賞味期限
      String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // 固有記号
      String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // 換算実績数量
      
      // ロットNo、製造年月日、賞味期限、固有記号、換算実績数量すべてに入力がない場合
      if (isBlankRow(resultLotRow))
      {
        // 処理を行わずに、次のレコード処理
        resultLotVo.next();
        continue;
      }
      
      // ロット管理区分が1：ロット管理品の場合のみロット項目入力チェックを行う。
      if (XxinvConstants.LOT_CTL_Y.equals(lotCtl))
      {
        // 製品識別区分が1:製品の場合
        if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
        {
          // 製造年月日に入力がない場合
          if (XxcmnUtility.isBlankOrNull(manufacturedDate))
          {
            // 必須エラー
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "ManufacturedDate",
                    manufacturedDate,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
          }

          // 賞味期限に入力がない場合
          if (XxcmnUtility.isBlankOrNull(useByDate))
          {
            // 必須エラー
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "UseByDate",
                    useByDate,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
          }
      
          // 固有記号に入力がない場合
          if (XxcmnUtility.isBlankOrNull(koyuCode))
          {
            // 必須エラー
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "KoyuCode",
                    koyuCode,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
          }

        // 製品識別区分が1:製品以外の場合
        } else
        {
          // ロットNoに入力がない場合
          if (XxcmnUtility.isBlankOrNull(lotNo))
          {
            // 必須エラー
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
          }
        }
      }

      // 換算実績数量に入力がない場合
      if (XxcmnUtility.isBlankOrNull(convertQuantity))
      {
        // 必須エラー
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                resultLotVo.getName(),
                resultLotRow.getKey(),
                "ConvertQuantity",
                convertQuantity,
                XxcmnConstants.APPL_XXINV, 
                XxinvConstants.XXINV10128));
                
      // 換算実績数量に入力がある場合
      } else
      {
        // 数値(999999999.999)でない場合はエラー
        if (!XxcmnUtility.chkNumeric(convertQuantity, 9, 3)) 
        {
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "ConvertQuantity",
                  convertQuantity,
                  XxcmnConstants.APPL_XXINV,         
                  XxinvConstants.XXINV10160));

        // マイナス値はエラー
        } else if (!XxcmnUtility.chkCompareNumeric(2, convertQuantity, "0"))
        {
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "ConvertQuantity",
                  convertQuantity,
                  XxcmnConstants.APPL_XXINV,         
                  XxinvConstants.XXINV10030));
        }
      }
      i++;
      // 次のレコードへ
      resultLotVo.next();
    }

    // エラーがある場合、インラインメッセージ出力
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // ************************* //
    // *  在庫会計期間チェック * //
    // ************************* //
    Date actualShipDate    = (Date)lineRow.getAttribute("ActualShipDate");    // 出庫実績日
    Date actualArrivalDate = (Date)lineRow.getAttribute("ActualArrivalDate"); // 入庫実績日

    // 出庫実績日がクローズしている場合
    if (XxinvUtility.chkStockClose(getOADBTransaction(), actualShipDate))
    {
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE) };
      // 在庫期間エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXINV, 
        XxinvConstants.XXINV10120, 
        tokens);  
    }

    // 入庫実績日がクローズしている場合
    if (XxinvUtility.chkStockClose(getOADBTransaction(), actualArrivalDate))
    {
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE) };
      // 在庫期間エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXINV, 
        XxinvConstants.XXINV10120, 
        tokens);  
    }

    if (i == 0)
    {
      ret = XxcmnConstants.STRING_FALSE;
    }
    return ret;
  }

  /***************************************************************************
   * 空行扱いかどうかを判定するメソッドです。
   * @param row          - 対象行
   * @return boolean     - true  : 入力項目がすべてNULL  false : 入力項目がNULLでない
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public boolean isBlankRow(OARow row)
  {
    String lotNo            = (String)row.getAttribute("LotNo");            // ロットNo
    Date   manufacturedDate = (Date)  row.getAttribute("ManufacturedDate"); // 製造年月日
    Date   useByDate        = (Date)  row.getAttribute("UseByDate");        // 賞味期限
    String koyuCode         = (String)row.getAttribute("KoyuCode");         // 固有記号
    String convertQuantity  = (String)row.getAttribute("ConvertQuantity");  // 換算実績数量
      
    // ロットNo、製造年月日、賞味期限、固有記号、換算実績数量すべてに入力がない場合
    if (XxcmnUtility.isBlankOrNull(lotNo)
      && XxcmnUtility.isBlankOrNull(manufacturedDate)
      && XxcmnUtility.isBlankOrNull(useByDate)
      && XxcmnUtility.isBlankOrNull(koyuCode)
      && XxcmnUtility.isBlankOrNull(convertQuantity))
    {
      return true;

    // いづれかに入力ありの場合
    } else
    {
      return false;
    }
  }

  /***************************************************************************
   * 出庫ロット画面の警告チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap checkWarningShipped() throws OAException
  {
    HashMap msg = new HashMap();

    // 明細VO取得
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number movLineId           = (Number)lineRow.getAttribute("MovLineId");          // 移動明細ID
    Number itemId              = (Number)lineRow.getAttribute("ItemId");             // 品目ID
    String itemCode            = (String)lineRow.getAttribute("ItemCode");           // 品目コード
    String itemName            = (String)lineRow.getAttribute("ItemName");           // 品目名
    Number numOfCases          = (Number)lineRow.getAttribute("NumOfCases");         // ケース入数
    Number shipToLocatId       = (Number)lineRow.getAttribute("ShipToLocatId");      // 入庫先ID
    String shipToLocatCode     = (String)lineRow.getAttribute("ShipToLocatCode");    // 入庫先コード
    String shippedLocatName    = (String)lineRow.getAttribute("ShippedLocatName");   // 出庫元保管倉庫名
    Number shippedLocatId      = (Number)lineRow.getAttribute("ShippedLocatId");     // 出庫元ID    
    Date   actualShipDate      = (Date)  lineRow.getAttribute("ActualShipDate");     // 出庫実績日
    Date   actualArrivalDate   = (Date)  lineRow.getAttribute("ActualArrivalDate");  // 入庫実績日
    Date   scheduleShipDate    = (Date)  lineRow.getAttribute("ScheduleShipDate");   // 出庫予定日
    Date   scheduleArrivalDate = (Date)  lineRow.getAttribute("ScheduleArrivalDate");// 入庫予定日
    String lotCtl              = (String)lineRow.getAttribute("LotCtl");             // ロット管理区分
    String status              = (String)lineRow.getAttribute("Status");             // ステータス
    String recordTypeCode      = (String)lineRow.getAttribute("RecordTypeCode");     // レコードタイプ 20:出庫実績
    String documentTypeCode    = (String)lineRow.getAttribute("DocumentTypeCode");   // 文書タイプ
    String productFlg          = (String)lineRow.getAttribute("ProductFlg");         // 製品識別区分
        
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;

    // 警告情報格納用
    String[]  lotRevErrFlgRow   = new String[resultLotVo.getRowCount()]; // ロット逆転防止チェックエラーフラグ
    String[]  minusErrFlgRow    = new String[resultLotVo.getRowCount()]; // マイナス在庫チェックエラーフラグ   
    String[]  exceedErrFlgRow   = new String[resultLotVo.getRowCount()]; // 引当可能在庫数超過チェックエラーフラグ   
    String[]  itemNameRow       = new String[resultLotVo.getRowCount()]; // 品目名
    String[]  lotNoRow          = new String[resultLotVo.getRowCount()]; // ロットNo
    String[]  shipToLocCodeRow  = new String[resultLotVo.getRowCount()]; // 入庫先コード
    String[]  revDateRow        = new String[resultLotVo.getRowCount()]; // 逆転日付
    String[]  manuDateRow       = new String[resultLotVo.getRowCount()]; // 製造年月日
    String[]  koyuCodeRow       = new String[resultLotVo.getRowCount()]; // 固有記号
    String[]  stockRow          = new String[resultLotVo.getRowCount()]; // 手持数量
    String[]  shippedLocNameRow = new String[resultLotVo.getRowCount()]; // 出庫元保管倉庫名

    // 1行目
    resultLotVo.first();

    // PVO取得
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // ロット逆転チェック不要フラグ取得
    String lotRevNotExe = (String)pvoRow.getAttribute("lotRevNotExe");

    // 全件ループ
    while (resultLotVo.getCurrentRow() != null)
    {
      // 処理対象行を取得
      resultLotRow = (OARow)resultLotVo.getCurrentRow();
      Number lotId            = (Number)resultLotRow.getAttribute("LotId");            // ロットID
      String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ロットNo
      Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // 製造年月日
      Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // 賞味期限
      String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // 固有記号
      String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // 換算数量        

      // ロットNo、製造年月日、賞味期限、固有記号、換算実績数量すべてに入力がない場合
      if (isBlankRow(resultLotRow))
      {
        // 処理を行わずに、次のレコード処理
        resultLotVo.next();
        continue;
      }

      // 警告エラー用
      lotRevErrFlgRow  [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // ロット逆転防止チェックエラーフラグ
      minusErrFlgRow   [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // マイナス在庫チェックエラーフラグ 
      exceedErrFlgRow  [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // 引当可能在庫数超過チェックエラーフラグ   
      itemNameRow      [resultLotVo.getCurrentRowIndex()] = itemName;         // 品目名
      lotNoRow         [resultLotVo.getCurrentRowIndex()] = lotNo;            // ロットNo
      shipToLocCodeRow [resultLotVo.getCurrentRowIndex()] = shipToLocatCode;  // 入庫先コード
      revDateRow       [resultLotVo.getCurrentRowIndex()] = new String();     // 逆転日付
      manuDateRow      [resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(manufacturedDate); // 製造年月日
      koyuCodeRow      [resultLotVo.getCurrentRowIndex()] = koyuCode;         // 固有記号
      stockRow         [resultLotVo.getCurrentRowIndex()] = new String();     // 手持数量
      shippedLocNameRow[resultLotVo.getCurrentRowIndex()] = shippedLocatName; // 出庫元保管倉庫名     

      // *************************** //
      // *  ロット逆転防止チェック * //
      // *************************** //
      // * 以下の条件に当てはまる場合、チェックを行う。
      // * ・ロット管理区分が1：ロット管理品
      // * ・ロット逆転チェック不要フラグがNull
      // * ・製品識別区分が1:製品
      // * ・ステータスが02:依頼済　03:調整中  05:入庫報告有のいづれか
      if (XxinvConstants.LOT_CTL_Y.equals(lotCtl)
        && XxcmnUtility.isBlankOrNull(lotRevNotExe)
          && XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg)
          && (XxinvConstants.STATUS_02.equals(status)
            || XxinvConstants.STATUS_03.equals(status)
            || XxinvConstants.STATUS_05.equals(status)))
      {
        Date standardDate = null;
        // 入庫実績日がNULLの場合
        if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
        {
          standardDate = scheduleArrivalDate; // 入庫予定日を適用日とする。
          
        // 入庫実績日がでない場合
        } else
        {
          standardDate = actualArrivalDate;   // 入庫実績日を適用日とする。
        }
        // ロット逆転防止チェック
        HashMap data = XxinvUtility.doCheckLotReversal(
                         getOADBTransaction(),
                         itemCode,
                         lotNo,
                         shipToLocatId,
                         standardDate);

        Number result  = (Number)data.get("result");  // 処理結果
        Date   revDate = (Date)  data.get("revDate"); // 逆転日付

        // API実行結果が1:エラーの場合
        if (XxinvConstants.RETURN_NOT_EXE.equals(result))
        {
          // ロット逆転防止エラーフラグをYに設定
          lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          revDateRow[resultLotVo.getCurrentRowIndex()]      = XxcmnUtility.stringValue(revDate); // 逆転日付
        }
      }

      // ******************************** //
      // * 手持在庫数量・引当可能数取得 * //
      // ******************************** //
      // 手持在庫数量算出API実行
      Number stockQyt = XxinvUtility.getStockQty(
                          getOADBTransaction(),
                          shippedLocatId,
                          itemId,
                          lotId,
                          lotCtl);
      // 警告エラー用
      stockRow[resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(stockQyt); // 手持数量
        
      // 引当可能数算出API実行
      Number canEncQty = XxinvUtility.getCanEncQty(
                           getOADBTransaction(),
                           shippedLocatId,
                           itemId,
                           lotId,
                           lotCtl);

      double stockQtyD       = XxcmnUtility.doubleValue(stockQyt);        // 手持在庫数量
      double canEncQtyD      = XxcmnUtility.doubleValue(canEncQty);       // 引当可能数
      double actualQtyInputD = doConversion(convertQuantity, numOfCases); // 実績数量(入力値)

      // ステータスが04：出庫報告有 OR 06：入出庫報告有の場合
      if (XxinvConstants.STATUS_04.equals(status) || XxinvConstants.STATUS_06.equals(status))
      {
        double resultActualQtyD = 0;
        // 実績ロットがある場合
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // 移動明細ID
              documentTypeCode,              // 文書タイプ
              recordTypeCode,                // レコードタイプ
              lotId))                        // ロットID
        {
          // 実績数量(実績ロット)取得
          resultActualQtyD = XxcmnUtility.doubleValue(
                               XxinvUtility.getActualQuantity(
                                 getOADBTransaction(),
                                 movLineId,             // 移動明細ID
                                 documentTypeCode,      // 文書タイプ
                                 recordTypeCode,        // レコードタイプ
                                 lotId));               // ロットID
        }
        // 実績数量(実績ロット) < 実績数量(入力値) (実績数量を増やして登録する)場合のみチェック行う
        if (resultActualQtyD < actualQtyInputD)
        {
          // ********************************* //
          // *   引当可能在庫数超過チェック  * //
          // ********************************* //
          // 引当可能数 - (実績数量(入力値) - 実績数量(実績ロット))が0より小さくなる場合、警告
          if ((canEncQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
          {
            // 引当可能在庫数超過チェックエラーフラグをYに設定
            exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }

          // *************************** //
          // *   マイナス在庫チェック  * //
          // *************************** //
          // 手持在庫数量 - (実績数量(入力値) - 実績数量(実績ロット))が0より小さくなる場合、警告
          if ((stockQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
          {
            // マイナス在庫チェックエラーフラグをYに設定
            minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;              
          }
        }
          
      // ステータスが02：依頼済 OR 03：調整中 OR 05：入庫報告有の場合
      } else if (XxinvConstants.STATUS_02.equals(status)
          || XxinvConstants.STATUS_03.equals(status) 
          || XxinvConstants.STATUS_05.equals(status))
      { 
        // ********************************* //
        // *   引当可能在庫数超過チェック  * //
        // ********************************* //
        // 指示ロットがある場合
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // 移動明細ID
              documentTypeCode,              // 文書タイプ
              XxinvConstants.RECORD_TYPE_10, // レコードタイプ 10:指示
              lotId))                        // ロットID
        {
          // 実績数量(指示ロット)取得
          double indicateActualQtyD = XxcmnUtility.doubleValue(
                                         XxinvUtility.getActualQuantity(
                                           getOADBTransaction(),
                                           movLineId,                     // 移動明細ID
                                           documentTypeCode,              // 文書タイプ
                                           XxinvConstants.RECORD_TYPE_10, // レコードタイプ 10:指示
                                           lotId));                       // ロットID

          // * 以下の条件すべてに当てはまる場合
          // * ・出庫予定日 > 出庫実績日 (前倒しで出荷した場合)
          // * ・引当可能数 - 実績数量(入力値) が0より小さくなる場合 
          if (XxcmnUtility.chkCompareDate(1, scheduleShipDate, actualShipDate)
            && ((canEncQtyD - actualQtyInputD) < 0))
          {
            // 引当可能在庫数超過チェックエラーフラグをYに設定
            exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;

          // * 以下の条件すべてに当てはまる場合
          // * ・実績数量(指示ロット) < 実績数量(入力値) (指示ロットより多く登録する場合)
          // * ・引当可能数 - (実績数量(入力値) - 実績数量(指示ロット)) が0より小さくなる場合
          } else if ((indicateActualQtyD < actualQtyInputD)
              && ((canEncQtyD - (actualQtyInputD - indicateActualQtyD)) < 0))
          {
            // 引当可能在庫数超過チェックエラーフラグをYに設定
            exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }

        // 指示ロットがない場合
        } else
        {
          // 引当可能数 - 実績数量(入力値) が0より小さくなる場合
          if ((canEncQtyD - actualQtyInputD) < 0)
          {
            // 引当可能在庫数超過チェックエラーフラグをYに設定
            exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }            
        }

        // *************************** //
        // *   マイナス在庫チェック  * //
        // *************************** //
        // 手持在庫数量 - 実績数量(入力値) が0より小さくなる場合
        if ((stockQtyD - actualQtyInputD) < 0)
        {
          // マイナス在庫チェックエラーフラグをYに設定
          minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
        }
      }

      // 次のレコードへ
      resultLotVo.next();
    } 
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow);  // ロット逆転防止チェックエラーフラグ
    msg.put("minusErrFlg",      (String[])minusErrFlgRow);   // マイナス在庫チェックエラーフラグ 
    msg.put("exceedErrFlg",     (String[])exceedErrFlgRow);  // 引当可能在庫数超過チェックエラーフラグ
    msg.put("itemName",         (String[])itemNameRow);      // 品目名
    msg.put("lotNo",            (String[])lotNoRow);         // ロットNo
    msg.put("shipToLocCode",    (String[])shipToLocCodeRow); // 入庫先コード
    msg.put("revDate",          (String[])revDateRow);       // 逆転日付
    msg.put("manufacturedDate", (String[])manuDateRow);      // 製造年月日
    msg.put("koyuCode",         (String[])koyuCodeRow);      // 固有記号
    msg.put("stock",            (String[])stockRow);         // 手持数量
    msg.put("shippedLocName",   (String[])shippedLocNameRow);// 出庫先保管倉庫名

    return msg;
  }

  /***************************************************************************
   * 入庫ロット画面の警告チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap checkWarningShipTo() throws OAException
  {
    HashMap msg = new HashMap();

    // 明細VO取得
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number movLineId           = (Number)lineRow.getAttribute("MovLineId");          // 移動明細ID
    Number itemId              = (Number)lineRow.getAttribute("ItemId");             // 品目ID
    String itemCode            = (String)lineRow.getAttribute("ItemCode");           // 品目コード
    String itemName            = (String)lineRow.getAttribute("ItemName");           // 品目名
    Number numOfCases          = (Number)lineRow.getAttribute("NumOfCases");         // ケース入数
    Number shipToLocatId       = (Number)lineRow.getAttribute("ShipToLocatId");      // 入庫先ID
    String shipToLocatCode     = (String)lineRow.getAttribute("ShipToLocatCode");    // 入庫先コード
    String shipToLocatName     = (String)lineRow.getAttribute("ShipToLocatName");    // 入庫元保管倉庫名
    Date   actualArrivalDate   = (Date)  lineRow.getAttribute("ActualArrivalDate");  // 入庫実績日
    Date   scheduleArrivalDate = (Date)  lineRow.getAttribute("ScheduleArrivalDate");// 入庫予定日
    String lotCtl              = (String)lineRow.getAttribute("LotCtl");             // ロット管理区分
    String status              = (String)lineRow.getAttribute("Status");             // ステータス
    String recordTypeCode      = (String)lineRow.getAttribute("RecordTypeCode");     // レコードタイプ 30:入庫実績
    String documentTypeCode    = (String)lineRow.getAttribute("DocumentTypeCode");   // 文書タイプ
    String productFlg          = (String)lineRow.getAttribute("ProductFlg");         // 製品識別区分
        
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;

    // 警告情報格納用
    String[]  lotRevErrFlgRow   = new String[resultLotVo.getRowCount()]; // ロット逆転防止チェックエラーフラグ
    String[]  shortageErrFlgRow = new String[resultLotVo.getRowCount()]; // 引当可能在庫数不足チェックエラーフラグ   
    String[]  itemNameRow       = new String[resultLotVo.getRowCount()]; // 品目名
    String[]  lotNoRow          = new String[resultLotVo.getRowCount()]; // ロットNo
    String[]  shipToLocCodeRow  = new String[resultLotVo.getRowCount()]; // 入庫先コード
    String[]  revDateRow        = new String[resultLotVo.getRowCount()]; // 逆転日付
    String[]  manuDateRow       = new String[resultLotVo.getRowCount()]; // 製造年月日
    String[]  koyuCodeRow       = new String[resultLotVo.getRowCount()]; // 固有記号
    String[]  shipToLocNameRow  = new String[resultLotVo.getRowCount()]; // 出庫元保管倉庫名

    // 1行目
    resultLotVo.first();

    // PVO取得
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // ロット逆転チェック不要フラグ取得
    String lotRevNotExe = (String)pvoRow.getAttribute("lotRevNotExe");

    // 全件ループ
    while (resultLotVo.getCurrentRow() != null)
    {
      // 処理対象行を取得
      resultLotRow = (OARow)resultLotVo.getCurrentRow();
      Number lotId            = (Number)resultLotRow.getAttribute("LotId");            // ロットID
      String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ロットNo
      Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // 製造年月日
      Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // 賞味期限
      String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // 固有記号
      String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // 換算数量        

      // ロットNo、製造年月日、賞味期限、固有記号、換算実績数量すべてに入力がない場合
      if (isBlankRow(resultLotRow))
      {
        // 処理を行わずに、次のレコード処理
        resultLotVo.next();
        continue;
      }

      // 警告エラー用
      lotRevErrFlgRow  [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // ロット逆転防止チェックエラーフラグ
      shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // 引当可能在庫数不足チェックエラーフラグ   
      itemNameRow      [resultLotVo.getCurrentRowIndex()] = itemName;                // 品目名
      lotNoRow         [resultLotVo.getCurrentRowIndex()] = lotNo;                   // ロットNo
      shipToLocCodeRow [resultLotVo.getCurrentRowIndex()] = shipToLocatCode;         // 入庫先コード
      revDateRow       [resultLotVo.getCurrentRowIndex()] = new String();           // 逆転日付
      manuDateRow      [resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(manufacturedDate); // 製造年月日
      koyuCodeRow      [resultLotVo.getCurrentRowIndex()] = koyuCode;                // 固有記号
      shipToLocNameRow [resultLotVo.getCurrentRowIndex()] = shipToLocatName;         // 入庫元保管倉庫名     

      // *************************** //
      // *  ロット逆転防止チェック * //
      // *************************** //
      // * 以下の条件に当てはまる場合、チェックを行う。
      // * ・ロット管理区分が1：ロット管理品
      // * ・ロット逆転チェック不要フラグがNull
      // * ・製品識別区分が1:製品
      // * ・ステータスが02:依頼済　03:調整中  04:出庫報告有のいづれか
      if (XxinvConstants.LOT_CTL_Y.equals(lotCtl)
        && XxcmnUtility.isBlankOrNull(lotRevNotExe)
          && XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg)
          &&(XxinvConstants.STATUS_02.equals(status)
            || XxinvConstants.STATUS_03.equals(status)
            || XxinvConstants.STATUS_04.equals(status)))
      {
        // ロット逆転防止チェック
        HashMap data = XxinvUtility.doCheckLotReversal(
                         getOADBTransaction(),
                         itemCode,
                         lotNo,
                         shipToLocatId,
                         actualArrivalDate);

        Number result  = (Number)data.get("result");  // 処理結果
        Date   revDate = (Date)  data.get("revDate"); // 逆転日付

        // API実行結果が1:エラーの場合
        if (XxinvConstants.RETURN_NOT_EXE.equals(result))
        {
          // ロット逆転防止エラーフラグをYに設定
          lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          revDateRow[resultLotVo.getCurrentRowIndex()]      = XxcmnUtility.stringValue(revDate); // 逆転日付
        }
      }
        
      // ******************** //
      // *  引当可能数取得  * //
      // ******************** //       
      // 引当可能数算出API実行
      Number canEncQty = XxinvUtility.getCanEncQty(
                           getOADBTransaction(),
                           shipToLocatId,
                           itemId,
                           lotId,
                           lotCtl);
      double canEncQtyD      = XxcmnUtility.doubleValue(canEncQty);       // 引当可能数
      double actualQtyInputD = doConversion(convertQuantity, numOfCases); // 実績数量(入力値)

      // ステータスが05：入庫報告有 OR 06：入出庫報告有の場合
      if (XxinvConstants.STATUS_05.equals(status) || XxinvConstants.STATUS_06.equals(status))
      {
        double resultActualQtyD = 0;
        // 実績ロットがある場合
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // 移動明細ID
              documentTypeCode,              // 文書タイプ
              recordTypeCode,                // レコードタイプ
              lotId))                        // ロットID
        {
          // 実績数量(実績ロット)取得
          resultActualQtyD = XxcmnUtility.doubleValue(
                               XxinvUtility.getActualQuantity(
                                 getOADBTransaction(),
                                 movLineId,             // 移動明細ID
                                 documentTypeCode,      // 文書タイプ
                                 recordTypeCode,        // レコードタイプ
                                 lotId));               // ロットID
        }

        // 実績数量(実績ロット) > 実績数量(入力値) (実績数量を減らして登録する場合)のみチェック行う
        if (resultActualQtyD > actualQtyInputD)
        {
          // ********************************* //
          // *   引当可能在庫数不足チェック  * //
          // ********************************* //
          // 引当可能数 - (実績数量(実績ロット) - 実績数量(入力値)) が0より小さくなる場合、警告
          if ((canEncQtyD - (resultActualQtyD - actualQtyInputD)) < 0)
          {
            // 引当可能在庫数不足チェックエラーフラグをYに設定
            shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }
        }
          
      // ステータスが02：依頼済 OR 03：調整中 OR 04：出庫報告有の場合
      } else if (XxinvConstants.STATUS_02.equals(status)
          || XxinvConstants.STATUS_03.equals(status) 
          || XxinvConstants.STATUS_04.equals(status))
      { 

        // ********************************* //
        // *   引当可能在庫数不足チェック  * //
        // ********************************* //
        // 指示ロットがある場合のみチェックを行う
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // 移動明細ID
              documentTypeCode,              // 文書タイプ
              XxinvConstants.RECORD_TYPE_10, // レコードタイプ 10:指示
              lotId))                        // ロットID
        { 
          // 実績数量(指示ロット)取得
          double indicateActualQtyD = XxcmnUtility.doubleValue(
                                         XxinvUtility.getActualQuantity(
                                           getOADBTransaction(),
                                           movLineId,                     // 移動明細ID
                                           documentTypeCode,              // 文書タイプ
                                           XxinvConstants.RECORD_TYPE_10, // レコードタイプ 10:指示
                                           lotId));                       // ロットID

          // * 以下の条件すべてに当てはまる場合
          // * ・入庫予定日 < 入庫実績日 (後倒しで入庫した場合)
          // * ・引当可能数 - 実績数量(入力値) が0より小さくなる場合 
          if (XxcmnUtility.chkCompareDate(1, actualArrivalDate, scheduleArrivalDate)
            && ((canEncQtyD - actualQtyInputD) < 0))
          {
            // 引当可能在庫数不足チェックエラーフラグをYに設定
            shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;

          // * 以下の条件すべてに当てはまる場合
          // * ・実績数量(指示ロット) > 実績数量(入力値) (指示ロットより少なく登録する場合)
          // * ・引当可能数 - (実績数量(指示ロット) - 実績数量(入力値))が0より小さくなる場合
          } else if ((indicateActualQtyD > actualQtyInputD) 
              && ((canEncQtyD - (indicateActualQtyD - actualQtyInputD)) < 0))
          {
            // 引当可能在庫数不足チェックエラーフラグをYに設定
            shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }           
        }
      }

      // 次のレコードへ
      resultLotVo.next();
    } 
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow);  // ロット逆転防止チェックエラーフラグ
    msg.put("shortageErrFlg",   (String[])shortageErrFlgRow);// 引当可能在庫数不足チェックエラーフラグ
    msg.put("itemName",         (String[])itemNameRow);      // 品目名
    msg.put("lotNo",            (String[])lotNoRow);         // ロットNo
    msg.put("shipToLocCode",    (String[])shipToLocCodeRow); // 入庫先コード
    msg.put("revDate",          (String[])revDateRow);       // 逆転日付
    msg.put("manufacturedDate", (String[])manuDateRow);      // 製造年月日
    msg.put("koyuCode",         (String[])koyuCodeRow);      // 固有記号
    msg.put("shipToLocName",    (String[])shipToLocNameRow); // 入庫元保管倉庫名

    return msg;
  }
  
  /***************************************************************************
   * 実績数量に換算するメソッドです。
   * @param convertQuantity - 換算数量
   * @param numOfCases      - ケース入数
   * @return double         - 実績数量
   ***************************************************************************
   */
  public double doConversion(
    String convertQuantity,
    Number numOfCases)
  {    
    double convertQuantityD = Double.parseDouble(convertQuantity); // 換算数量
    double actualQuantityD  = 0; // 実績数量
    double numOfCasesD      = XxcmnUtility.doubleValue(numOfCases); // ケース入数

    // 実績数量 = 換算数量 * ケース入数
    return convertQuantityD * numOfCasesD;
  }

 /*****************************************************************************
   * 出庫ロット画面の登録処理を行うメソッドです。
   * @throws OAException - OA例外
   ****************************************************************************/
  public void entryDataShipped() throws OAException
  {    
    // ***************************** //
    // *  ロック取得・排他チェック * //
    // ***************************** //
    getLockAndChkExclusive();

    // 明細VO取得
    OAViewObject lineVo     = getXxinvLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");// 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");  // レコードタイプ
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");       // 移動明細ID
    Number movHeaderId      = (Number)lineRow.getAttribute("MovHdrId");        // 移動ヘッダID
    String productFlg       = (String)lineRow.getAttribute("ProductFlg");      // 製品識別区分
    String movNum           = (String)lineRow.getAttribute("MovNum");          // 移動番号
    String compActualFlg    = (String)lineRow.getAttribute("CompActualFlg");   // 実績計上済フラグ
    String status           = (String)lineRow.getAttribute("Status");          // ステータス
    String actualQtySum = null;

    // 終了メッセージ格納
    ArrayList infoMsg = new ArrayList(100);

    // ******************************** //
    // *  移動ロット詳細実績登録処理  * //
    // ******************************** //
    insertResultLot();

// 2008-07-14 Y.Yamamoto Del START
    // *********************************** // 
    // *  重量容積小口個数更新関数実行   * //
    // *********************************** //
//    Number ret = XxinvUtility.doUpdateLineItems(getOADBTransaction(), XxcmnConstants.BIZ_TYPE_MOV, movNum);

    // 重量容積小口更新関数の戻り値が1：エラーの場合
//    if (XxinvConstants.RETURN_NOT_EXE.equals(ret))
//    {
      // ロールバック
//      XxinvUtility.rollBack(getOADBTransaction());
      // 重量容積小口個数更新関数エラーメッセージ出力
//      throw new OAException(
//          XxcmnConstants.APPL_XXINV, 
//          XxinvConstants.XXINV10127);
//    }
// 2008-07-14 Y.yamamoto Del END
   
    // ********************** // 
    // *  実績数量合計取得  * //
    // ********************** //
    actualQtySum = XxinvUtility.getActualQuantitySum(
                     getOADBTransaction(),
                     movLineId,
                     documentTypeCode,
                     recordTypeCode);

    // ********************************** // 
    // *  移動明細出庫実績数量更新処理  * //
    // ********************************** //
    XxinvUtility.updateShippedQuantity(
      getOADBTransaction(),
      movLineId,
      actualQtySum);

    // 全移動明細出庫実績数量登録済チェック (true:登録済  false:未登録あり)
    boolean shippedResultFlag = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1");
    // 全移動明細入庫実績数量登録済チェック (true:登録済  false:未登録あり)
    boolean shipToResultFlag  = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2");

    // ステータスが02：依頼済 OR 03：調整中 OR 05：入庫報告有の場合
    if (XxinvConstants.STATUS_02.equals(status)
        || XxinvConstants.STATUS_03.equals(status) 
        || XxinvConstants.STATUS_05.equals(status))
    { 
      // 実績数量が登録済の場合、ステータスの更新を実行
      if (shippedResultFlag)
      {
        // ********************************** // 
        // *  移動ヘッダステータス更新処理  * //
        // ********************************** //
        updateStatus(movHeaderId, recordTypeCode);
      }

    // ステータスが04：出庫報告有 OR 06：入出庫報告有の場合
    } else if (XxinvConstants.STATUS_04.equals(status) || XxinvConstants.STATUS_06.equals(status))
    {
      // 実績計上済フラグがONの場合
      if (XxcmnConstants.STRING_Y.equals(compActualFlg))
      {
        // ************************************** // 
        // *  移動ヘッダ実績訂正フラグ更新処理  * //
        // ************************************** // 
        XxinvUtility.updateCorrectActualFlg(getOADBTransaction(), movHeaderId);
      }
    }

// 2008-07-14 Y.Yamamoto Add START
    // *********************************** // 
    // *  重量容積小口個数更新関数実行   * //
    // *********************************** //
    Number ret = XxinvUtility.doUpdateLineItems(getOADBTransaction(), XxcmnConstants.BIZ_TYPE_MOV, movNum);

    // 重量容積小口更新関数の戻り値が1：エラーの場合
    if (XxinvConstants.RETURN_NOT_EXE.equals(ret))
    {
      // ロールバック
      XxinvUtility.rollBack(getOADBTransaction());
      // 重量容積小口個数更新関数エラーメッセージ出力
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10127);
    }
// 2008-07-14 Y.yamamoto Add END

    // ***************** //
    // *  コミット     * //
    // ***************** //
    XxinvUtility.commit(getOADBTransaction());

// 2009-12-28 H.Itou Del Start 本稼動障害#695
//    // 移動明細の出庫実績数量・入庫実績数量が共にすべて登録済の場合
//    if (shippedResultFlag && shipToResultFlag)
//    {    
//      // ******************************************* // 
//      // *  移動入出庫実績登録処理(コンカレント)   * //
//      // ******************************************* //
//      HashMap param = new HashMap();
//      param.put("MovNum", movNum); // 移動番号
//      HashMap retHashMap = XxinvUtility.doMovShipActualMake(getOADBTransaction(), param);
//
//      // コンカレント正常終了の場合
//      if (XxcmnConstants.RETURN_SUCCESS.equals((String)retHashMap.get("retFlag")))
//      {
//        // コンカレント正常終了メッセージ取得
//        MessageToken[] tokens = new MessageToken[2];
//        tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
//        tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID,      retHashMap.get("requestId").toString());
//        infoMsg.add(
//          new OAException(
//                 XxcmnConstants.APPL_XXINV,
//                 XxinvConstants.XXINV10006,
//                 tokens,
//                 OAException.INFORMATION,
//                 null));
//      }
//    }
// 2009-12-28 H.Itou Del End

    // ******************** // 
    // *  再表示          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("movLineId",      movLineId.toString()); // 移動明細ID
    params.put("productFlg",     productFlg);           // 製品識別区分
    params.put("recordTypeCode", recordTypeCode);       // レコードタイプ 
    initialize(params);

    // 登録完了メッセージ取得
    infoMsg.add( new OAException(XxcmnConstants.APPL_XXINV,
                                  XxinvConstants.XXINV10161, 
                                  null, 
                                  OAException.INFORMATION, 
                                  null));

    // PVO取得
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // ロット逆転チェック不要フラグ設定
    pvoRow.setAttribute("lotRevNotExe", "1");

    // **************************** // 
    // *  登録完了メッセージ出力  * //
    // **************************** //
    if (infoMsg.size() > 0)
    {
      OAException.raiseBundledOAException(infoMsg);
    }   
  }

 /*****************************************************************************
   * 入庫ロット画面の登録処理を行うメソッドです。
   * @throws OAException - OA例外
   ****************************************************************************/
  public void entryDataShipTo() throws OAException
  {    
    // ***************************** //
    // *  ロック取得・排他チェック * //
    // ***************************** //
    getLockAndChkExclusive();

    // 明細VO取得
    OAViewObject lineVo     = getXxinvLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");// 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");  // レコードタイプ
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");       // 移動明細ID
    Number movHeaderId      = (Number)lineRow.getAttribute("MovHdrId");        // 移動ヘッダID
    String productFlg       = (String)lineRow.getAttribute("ProductFlg");      // 製品識別区分
    String movNum           = (String)lineRow.getAttribute("MovNum");          // 移動番号
    String compActualFlg    = (String)lineRow.getAttribute("CompActualFlg");   // 実績計上済フラグ
    String status           = (String)lineRow.getAttribute("Status");          // ステータス
    String actualQtySum = null;

    // 終了メッセージ格納
    ArrayList infoMsg = new ArrayList(100);

    // ******************************** //
    // *  移動ロット詳細実績登録処理  * //
    // ******************************** //
    insertResultLot();

    // ********************** // 
    // *  実績数量合計取得  * //
    // ********************** //
    actualQtySum = XxinvUtility.getActualQuantitySum(
                     getOADBTransaction(),
                     movLineId,
                     documentTypeCode,
                     recordTypeCode);

    // ********************************** // 
    // *  移動明細入庫実績数量更新処理  * //
    // ********************************** //
    XxinvUtility.updateShipToQuantity(
      getOADBTransaction(),
      movLineId,
      actualQtySum);

    // 全移動明細出庫実績数量登録済チェック (true:登録済  false:未登録あり)
    boolean shippedResultFlag = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1");
    // 全移動明細入庫実績数量登録済チェック (true:登録済  false:未登録あり)
    boolean shipToResultFlag  = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2");

    // ステータスが02：依頼済 OR 03：調整中 OR 04：出庫報告有の場合
    if (XxinvConstants.STATUS_02.equals(status)
        || XxinvConstants.STATUS_03.equals(status) 
        || XxinvConstants.STATUS_04.equals(status))
    { 
      // 実績数量が登録済の場合、ステータスの更新を実行
      if (shipToResultFlag)
      {
        // ********************************** // 
        // *  移動ヘッダステータス更新処理  * //
        // ********************************** //
        updateStatus(movHeaderId, recordTypeCode);
      }

    // ステータスが05：入庫報告有 OR 06：入出庫報告有の場合
    } else if (XxinvConstants.STATUS_05.equals(status) || XxinvConstants.STATUS_06.equals(status))
    {
      // 実績計上済フラグがONの場合
      if (XxcmnConstants.STRING_Y.equals(compActualFlg))
      {
        // ************************************** // 
        // *  移動ヘッダ実績訂正フラグ更新処理  * //
        // ************************************** // 
        XxinvUtility.updateCorrectActualFlg(getOADBTransaction(), movHeaderId);
      }
    }
    
    // ***************** //
    // *  コミット     * //
    // ***************** //
    XxinvUtility.commit(getOADBTransaction());

// 2009-12-28 H.Itou Del Start 本稼動障害#695
//    // 移動明細の出庫実績数量・入庫実績数量が共にすべて登録済の場合
//    if (shippedResultFlag && shipToResultFlag)
//    {    
//      // ******************************************* // 
//      // *  移動入出庫実績登録処理(コンカレント)   * //
//      // ******************************************* //
//      HashMap param = new HashMap();
//      param.put("MovNum", movNum); // 移動番号
//      HashMap retHashMap = XxinvUtility.doMovShipActualMake(getOADBTransaction(), param);
//
//      // コンカレント正常終了の場合
//      if (XxcmnConstants.RETURN_SUCCESS.equals((String)retHashMap.get("retFlag")))
//      {
//        // コンカレント正常終了メッセージ取得
//        MessageToken[] tokens = new MessageToken[2];
//        tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
//        tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID,      retHashMap.get("requestId").toString());
//        infoMsg.add(
//          new OAException(
//                 XxcmnConstants.APPL_XXINV,
//                 XxinvConstants.XXINV10006,
//                 tokens,
//                 OAException.INFORMATION,
//                 null));
//      }
//    }
// 2009-12-28 H.Itou Del End

    // ******************** // 
    // *  再表示          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("movLineId",      movLineId.toString()); // 移動明細ID
    params.put("productFlg",     productFlg);           // 製品識別区分
    params.put("recordTypeCode", recordTypeCode);       // レコードタイプ 
    initialize(params);

    // 登録完了メッセージ取得
    infoMsg.add( new OAException(XxcmnConstants.APPL_XXINV,
                                  XxinvConstants.XXINV10161, 
                                  null, 
                                  OAException.INFORMATION, 
                                  null));

    // PVO取得
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // ロット逆転チェック不要フラグ設定
    pvoRow.setAttribute("lotRevNotExe", "1");
    // **************************** // 
    // *  登録完了メッセージ出力  * //
    // **************************** //
    if (infoMsg.size() > 0)
    {
      OAException.raiseBundledOAException(infoMsg);
    }   
  }

 /*****************************************************************************
  * ロックを取得し、排他チェックを行うメソッドです。
  * @throws OAException - OA例外
  ****************************************************************************/
  public void getLockAndChkExclusive() throws OAException
  {
    // 明細VO取得
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    Number movHdrId         = (Number)lineRow.getAttribute("MovHdrId");         // 移動ヘッダID
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");        // 移動明細ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // レコードタイプ
    String headerUpdateDate = (String)lineRow.getAttribute("HeaderUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate   = (String)lineRow.getAttribute("LineUpdateDate");   // 明細更新日時

    // ************************ //
    // *   移動ヘッダロック   * //
    // ************************ //
    // ロック取得に失敗した場合
    if (!XxinvUtility.getMovReqInstrHdrLock(getOADBTransaction(), movHdrId))
    {
      // ロックエラーメッセージ出力
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
    }

    // ********************** //
    // *   移動明細ロック   * //
    // ********************** //
    // ロック取得に失敗した場合
    if (!XxinvUtility.getMovReqInstrLineLock(getOADBTransaction(), movLineId))
    {
      // ロックエラーメッセージ出力
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
    }

    // *************************** //
    // *  移動ロット詳細ロック   * //
    // *************************** //
    // ロックエラーの場合
    if (!XxinvUtility.getMovLotDetailsLock(
          getOADBTransaction(),
          movLineId,
          documentTypeCode,
          recordTypeCode))
    {
      // ロックエラーメッセージ出力
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
    }
    
    // ******************************** //
    // *   移動ヘッダ排他チェック     * //
    // ******************************** //
    // 排他エラーの場合
    if (!XxinvUtility.chkExclusiveMovReqInstrHdr(getOADBTransaction(), movHdrId, headerUpdateDate))
    {
// 2008-07-10 H.Itou Mod START
      // 自分自身のコンカレント起動により更新された場合は排他エラーとしない
      if (!XxinvUtility.isMovHdrUpdForOwnConc(
             getOADBTransaction(),
             movHdrId,
             XxinvConstants.CONC_NAME_XXINV570001C))
      {
        // ロールバック
        XxinvUtility.rollBack(getOADBTransaction());
        
        // 排他エラーメッセージ出力
        throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10147);
      }
// 2008-07-10 H.Itou Mod END
    }

    // ******************************** //
    // *   移動明細排他チェック       * //
    // ******************************** //
    // 排他エラーの場合
    if (!XxinvUtility.chkExclusiveMovReqInstrLine(getOADBTransaction(), movLineId, lineUpdateDate))
    {
// 2008-07-10 H.Itou Mod START
      // 自分自身のコンカレント起動により更新された場合は排他エラーとしない
      if (!XxinvUtility.isMovLineUpdForOwnConc(
             getOADBTransaction(),
             movLineId,
             XxinvConstants.CONC_NAME_XXINV570001C))
      {
        // ロールバック
        XxinvUtility.rollBack(getOADBTransaction());

        // 排他エラーメッセージ出力
        throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10147);
      }
// 2008-07-10 H.Itou Mod END
    }
  }

  /***************************************************************************
   * 移動ロット詳細の実績登録、実績更新処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void insertResultLot() throws OAException
  {
    // 明細VO取得
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");         // 移動明細ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // レコードタイプ
      
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    resultLotVo.first();
    OARow resultLotRow = null;
      
    // 全件ループ
    while (resultLotVo.getCurrentRow() != null)
    {
      resultLotRow = (OARow)resultLotVo.getCurrentRow();
      Number lotId            = (Number)resultLotRow.getAttribute("LotId");            // ロットID
      String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ロットNo
      Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // 製造年月日
      Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // 賞味期限
      String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // 固有記号
      String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // 換算実績数量

      // ロットNo、製造年月日、賞味期限、固有記号、換算実績数量すべてに入力がない場合
      if (isBlankRow(resultLotRow))
      {
        // 処理を行わずに、次のレコード処理
        resultLotVo.next();
        continue;
      }

      // 実績ロットデータHashMap取得
      HashMap data = getResultLotHashMap(resultLotRow, lineRow);
      
      // 実績ロットが登録済の場合(実績更新時)
      if (XxinvUtility.checkMovLotDtl(
            getOADBTransaction(),
            movLineId,           // 移動明細ID
            documentTypeCode,      // 文書タイプ
            recordTypeCode,        // レコードタイプ
            lotId))                // ロットID
      {    
        // ************************************ // 
        // *  移動ロット詳細実績数量更新処理  * //
        // ************************************ //
        XxinvUtility.updateActualQuantity(getOADBTransaction(), data);
        
      // 実績ロットが登録済でない場合(実績新規時)
      } else
      {       
        // **************************** // 
        // *  移動ロット詳細登録処理  * //
        // **************************** //       
        XxinvUtility.insertMovLotDetails(getOADBTransaction(), data);          

      }
      // 次のレコードへ
      resultLotVo.next();
    }
  }

  /***************************************************************************
   * 実績ロットデータをHashMapで取得するメソッドです。
   * @param resultLotRow - 実績ロットROW
   * @param lineRow      - 明細ROW
   * @return HashMap     - 実績ロットHashMap
   ***************************************************************************
   */
  public HashMap getResultLotHashMap(
    OARow resultLotRow,
    OARow lineRow)
  {
    String convertQuantity = (String)resultLotRow.getAttribute("ConvertQuantity");
    Number numOfCases      = (Number)lineRow.getAttribute("NumOfCases");
    String recordTypeCode  = (String)lineRow.getAttribute("RecordTypeCode");
    
    HashMap ret = new HashMap();

    ret.put("movLineId",          lineRow.getAttribute("MovLineId"));             // 移動明細ID
    ret.put("documentTypeCode",   lineRow.getAttribute("DocumentTypeCode"));      // 文書タイプ
    ret.put("recordTypeCode",     lineRow.getAttribute("RecordTypeCode"));        // レコードタイプ
    ret.put("itemId",             lineRow.getAttribute("ItemId"));                // 品目ID
    ret.put("itemCode",           lineRow.getAttribute("ItemCode"));              // 品目コード
    ret.put("lotId",              resultLotRow.getAttribute("LotId"));            // ロットID
    ret.put("lotNo",              resultLotRow.getAttribute("LotNo"));            // ロットNo
    ret.put("manufacturedDate",   resultLotRow.getAttribute("ManufacturedDate")); // 製造年月日
    ret.put("useByDate",          resultLotRow.getAttribute("UseByDate"));        // 賞味期限
    ret.put("koyuCode",           resultLotRow.getAttribute("KoyuCode"));         // 固有記号
    ret.put("actualQuantity",     Double.toString(doConversion(convertQuantity, numOfCases)));// 実績数量   
     // レコードタイプが20：出庫実績の場合
    if (XxinvConstants.RECORD_TYPE_20.equals(recordTypeCode))
    {
      ret.put("actualDate",         lineRow.getAttribute("ActualShipDate"));      // 実績日 = 出庫実績日

    //  レコードタイプが30：入庫実績の場合
    } else
    {
      ret.put("actualDate",         lineRow.getAttribute("ActualArrivalDate"));   // 実績日 = 入庫実績日
    }

    return ret;
  }

  /***************************************************************************
   * 移動依頼/指示ヘッダステータスを更新するメソッドです。
   * @param  movHeaderId     - 移動ヘッダID
   * @param  recordTypeCode  - レコードタイプ 20:出庫実績 30:入庫実績
   * @throws OAException     - OA例外
   ***************************************************************************
   */
  public void updateStatus(
    Number movHeaderId, 
    String recordTypeCode)
  throws OAException
  {
    String status = null; // ステータス

    // 出庫ロット実績画面の場合
    if (XxinvConstants.RECORD_TYPE_20.equals(recordTypeCode))
    {
      // 全移動明細入庫実績数量登録済チェック
      if (XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2"))
      {
        // 入庫実績登録済の場合
        status = XxinvConstants.STATUS_06; // ステータス 06 入出庫報告有

      } else
      {
        // 入庫実績未登録ありの場合
        status = XxinvConstants.STATUS_04; // ステータス 04 出庫報告有
      }      

    // 入庫ロット実績画面の場合
    } else
    {
      // 全移動明細出庫実績数量登録済チェック
      if (XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1"))
      {
        // 出庫実績登録済の場合
        status = XxinvConstants.STATUS_06; // ステータス 06 入出庫報告有

      } else
      {
        // 出庫実績未登録ありの場合
        status = XxinvConstants.STATUS_05; // ステータス 05 入庫報告有        
      }      
    }

    XxinvUtility.updateStatus(
      getOADBTransaction(),
      movHeaderId,
      status);
  }

  /**
   * 
   * Container's getter for XxinvLineVO1
   */
  public XxinvLineVOImpl getXxinvLineVO1()
  {
    return (XxinvLineVOImpl)findViewObject("XxinvLineVO1");
  }


  /**
   * 
   * Container's getter for XxinvResultLotVO1
   */
  public XxinvResultLotVOImpl getXxinvResultLotVO1()
  {
    return (XxinvResultLotVOImpl)findViewObject("XxinvResultLotVO1");
  }

  /**
   * 
   * Container's getter for XxInvMovementShippedLotPVO1
   */
  public XxInvMovementShippedLotPVOImpl getXxInvMovementShippedLotPVO1()
  {
    return (XxInvMovementShippedLotPVOImpl)findViewObject("XxInvMovementShippedLotPVO1");
  }

  /**
   * 
   * Container's getter for XxinvIndicateLotVO1
   */
  public XxinvIndicateLotVOImpl getXxinvIndicateLotVO1()
  {
    return (XxinvIndicateLotVOImpl)findViewObject("XxinvIndicateLotVO1");
  }


}