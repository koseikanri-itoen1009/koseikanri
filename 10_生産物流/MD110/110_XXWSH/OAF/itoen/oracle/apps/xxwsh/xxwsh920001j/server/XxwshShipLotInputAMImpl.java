/*============================================================================
* ファイル名 : XxwshShipLotInputAMImpl
* 概要説明   : 入出荷実績ロット入力画面アプリケーションモジュール
* バージョン : 1.9
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  伊藤ひとみ   新規作成
* 2008-06-13 1.1  伊藤ひとみ   出荷実績計上済でも出荷実績数量に登録がない場合は受注複写処理を行わない。
* 2008-06-13 1.2  伊藤ひとみ   出荷実績計上済でもヘッダに紐付く出荷実績数量が
*                              すべて登録済出荷実績数量に登録がない場合は
*                              受注複写処理を行わない。
* 2008-06-27 1.3  伊藤ひとみ   結合不具合TE080_400#157
* 2008-07-23 1.4  伊藤ひとみ   内部課題#32  換算する場合で、ケース入数が0以下はエラー
*                              内部変更#174 実績計上済区分がYの場合のみ受注コピー処理を行う
* 2008-09-25 1.5  伊藤ひとみ   T_TE080_BPO_400指摘93 受注タイプ：廃棄・見本の場合、ロットステータスチェックを行わない
* 2008-10-17 1.6  伊藤ひとみ   統合テスト指摘346 入庫実績の場合も在庫クローズチェックを行う。
* 2009-03-04 1.7  飯田　甫     本番障害#1234対応
* 2014-11-11 1.8  桐生和幸     E_本稼働_12237対応
* 2015-03-27 1.9  桐生和幸     E_本稼働_12237緊急対応
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

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
 * 入出荷実績ロット入力画面アプリケーションモジュールです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.6
 ***************************************************************************
 */
public class XxwshShipLotInputAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshShipLotInputAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxwsh.xxwsh920001j.server", "XxwshShipLotInputAMLocal");
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
    OAViewObject pvo = getXxwshShipLotInputPVO1();   
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
    // *  パラメータチェック * //
    // *********************** //
    checkParams(params);

    // *********************** //
    // *   表示データ取得    * //
    // *********************** //
    doSearch(params);

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
    String orderLineId      = (String)params.get("orderLineId");      // 受注明細アドオンID
    String callPictureKbn   = (String)params.get("callPictureKbn");   // 呼出画面区分
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // 明細更新日時
    String exeKbn           = (String)params.get("exeKbn");           // 起動区分   
    String recordTypeCode   = (String)params.get("recordTypeCode");   // レコードタイプ 20:出庫実績 30:入庫実績
    String documentTypeCode = null; // 文書タイプ

    // 文書タイプ決定
    // 呼出画面区分が1:出荷依頼入力画面の場合
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      documentTypeCode = XxwshConstants.DOC_TYPE_SHIP; // 10:出荷依頼

    // それ以外の場合
    } else
    {
      documentTypeCode = XxwshConstants.DOC_TYPE_SUPPLY; // 30:支給指示
    }

// 2008-07-23 H.Itou ADD START
    // ************************* //    
    // *   ケース入数チェック  * //
    // ************************* //
    // 呼出画面区分が1:出荷依頼入力画面の場合のみチェック
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      // 明細IDから品目コードを取得
      String itemCode = XxwshUtility.getItemCode(getOADBTransaction(), orderLineId);

       // 換算する場合に、品目のケース入数0以下の値の場合、エラー
      if (!XxwshUtility.checkNumOfCases(getOADBTransaction(), itemCode))
      {
        // 項目制御(戻るボタン以外非表示
        itemControl(XxcmnConstants.STRING_Y);
      
        // トークン生成
        MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM_NO, itemCode) };

        // エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10605,
          tokens);

      }
    }   
// 2008-07-23 H.Itou ADD END

    // ********************** //    
    // *   明細検索         * //
    // ********************** //
    XxwshLineVOImpl lineVo = getXxwshLineVO1();
    lineVo.initQuery(
      orderLineId,
      callPictureKbn);
      
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

    lineRow.setAttribute("OrderLineId",       orderLineId);      // 受注明細アドオンID
    lineRow.setAttribute("CallPictureKbn",    callPictureKbn);   // 呼出画面区分
    lineRow.setAttribute("HeaderUpdateDate",  headerUpdateDate); // ヘッダ更新日時
    lineRow.setAttribute("LineUpdateDate",    lineUpdateDate);   // 明細更新日時
    lineRow.setAttribute("ExeKbn",            exeKbn);           // 起動区分 
    lineRow.setAttribute("DocumentTypeCode",  documentTypeCode); // 文書タイプ
    lineRow.setAttribute("RecordTypeCode",    recordTypeCode);   // レコードタイプ
    
    // 値取得
    String itemClassCode = (String)lineRow.getAttribute("ItemClassCode"); // 品目区分
    Number numOfCases    = (Number)lineRow.getAttribute("NumOfCases");    // ケース入数

    // *********************** //
    // *      項目制御       * //
    // *********************** //
    itemControl(XxcmnConstants.STRING_N);
    String updateFlg    = (String)lineRow.getAttribute("UpdateFlg"); // 更新区分：Nだと更新不可

    // ********************** //    
    // *   指示ロット検索   * //
    // ********************** //
    XxwshIndicateLotVOImpl indicateLotVo = getXxwshIndicateLotVO1();
    indicateLotVo.initQuery(
      orderLineId,
      documentTypeCode,
      itemClassCode,
      numOfCases);
    OARow indicateLotRow = (OARow)indicateLotVo.first();
    
    // レコードタイプが30：入庫実績かつ、指示ロットを取得できなかった場合
    if (XxwshConstants.RECORD_TYPE_STOC.equals(recordTypeCode) && (lineVo.getRowCount() == 0))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500); 
    } 
    
    // ********************** //    
    // *   実績ロット検索   * //
    // ********************** //
    XxwshResultLotVOImpl resultLotVo = getXxwshResultLotVO1();
    resultLotVo.initQuery(
      orderLineId,
      documentTypeCode,
      recordTypeCode,
      itemClassCode,
      numOfCases);
    OARow resultLotRow = (OARow)resultLotVo.first();
    
    // 登録可能かつ、実績ロットがない場合、指示ロットを検索
    if (!XxcmnConstants.STRING_N.equals(updateFlg) && (resultLotVo.getRowCount() == 0))
    {
      resultLotVo.initQuery(
        orderLineId,
        documentTypeCode,
        XxwshConstants.RECORD_TYPE_INST,
        itemClassCode,
        numOfCases);
      resultLotRow = (OARow)resultLotVo.first();
    }

    // 登録可能かつ、実績ロットがない場合、空行を表示
    if (!XxcmnConstants.STRING_N.equals(updateFlg) && (resultLotVo.getRowCount() == 0))
    {
      // デフォルトで1行表示する。
      addRow();
    }
  }
  
  /***************************************************************************
   * パラメータチェックを行うメソッドです。
   * @param params        - パラメータ
   * @throws OAException  - OA例外
   ***************************************************************************
   */
  public void checkParams(HashMap params) throws OAException
  {
    // パラメータ取得
    String callPictureKbn   = (String)params.get("callPictureKbn");   // 呼出画面区分
    String orderLineId      = (String)params.get("orderLineId");      // 受注明細アドオンID
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // 明細更新日時
    String exeKbn           = (String)params.get("exeKbn");           // 起動区分   

    // 呼出画面区分が設定されていない場合
    if (XxcmnUtility.isBlankOrNull(callPictureKbn))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_CALL_PICTURE_KBN) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }

    // 受注明細アドオンIDが設定されていない場合
    if (XxcmnUtility.isBlankOrNull(orderLineId))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_LINE_ID) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }

    // 明細更新日時が設定されていない場合
    if (XxcmnUtility.isBlankOrNull(lineUpdateDate))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }

    // ヘッダ更新日時が設定されていない場合
    if (XxcmnUtility.isBlankOrNull(headerUpdateDate))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }
    
    // 明細更新日時の書式がYYYY/MM/DD HH24:MI:SSでない場合
    if(!XxcmnUtility.chkDateFormat(
          getOADBTransaction(),
          lineUpdateDate,
          XxwshConstants.DATE_FORMAT))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13311, 
        tokens);     
    }
    
    // ヘッダ更新日時の書式がYYYY/MM/DD HH24:MI:SSでない場合
    if(!XxcmnUtility.chkDateFormat(
          getOADBTransaction(),
          headerUpdateDate,
          XxwshConstants.DATE_FORMAT))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);
      
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13311, 
        tokens);     
    }

    // 呼出画面区分が1:出荷依頼入力画面以外で、起動区分が設定されていない場合
    if (!XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn) && XxcmnUtility.isBlankOrNull(exeKbn))
    {
      // 項目制御(戻るボタン以外非表示
      itemControl(XxcmnConstants.STRING_Y);

      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_EXE_KBN) };
      // エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }
  }
  
  /***************************************************************************
   * 行挿入処理を行うメソッドです。
   ***************************************************************************
   */
  public void addRow()
  {
    // 明細VO取得
    OAViewObject lineVo = getXxwshLineVO1();
    // 1行目を取得
    OARow lineRow   = (OARow)lineVo.first();
    // 値取得
    String lotCtl           = (String)lineRow.getAttribute("LotCtl");           // ロット管理区分
    String itemClassCode    = (String)lineRow.getAttribute("ItemClassCode");    // 品目区分
        
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    // ROW取得
    OARow resultLotRow = (OARow)resultLotVo.createRow();

    // ロット管理外品の場合
    if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
    {
      // Switcherの制御
      resultLotRow.setAttribute("LotNoSwitcher" ,            "LotNoDisabled");           // ロットNo：入力不可
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// 製造年月日：入力不可
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // 賞味期限：入力不可
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // 固有記号：入力不可

      // デフォルト値の設定
      resultLotRow.setAttribute("LotId", XxwshConstants.DEFAULT_LOT);    // ロットID

    // 品目区分が5:製品の場合
    } else if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
    {
      // Switcherの制御
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoDisabled");          // ロットNo：入力不可
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateEnabled");// 製造年月日：入力可
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateEnabled");       // 賞味期限：入力可
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeEnabled");        // 固有記号：入力可

    // それ以外の場合
    } else
    {
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoEnabled");            // ロットNo：入力可
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// 製造年月日：入力不可
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // 賞味期限：入力不可
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // 固有記号：入力不可      
    }
    // 移動ロット詳細の新規ID取得
    Number movLotDtlId = XxwshUtility.getMovLotDtlId(getOADBTransaction());
    
    // デフォルト値の設定
    resultLotRow.setAttribute("MovLotDtlId",      movLotDtlId);             // 移動ロット詳細ID
    resultLotRow.setAttribute("NewRow",           XxcmnConstants.STRING_Y); // 新規行フラグ   
    resultLotRow.setAttribute("ActualQuantity",   new Number(0));           // 実績数量DB

    // 新規行挿入
    resultLotVo.last();
    resultLotVo.next();
    resultLotVo.insertRow(resultLotRow);
    resultLotRow.setNewRowState(Row.STATUS_INITIALIZED);
  } // addRow
  
  /***************************************************************************
   * 項目制御を行うメソッドです。
   * @param errFlag   - Y:エラーの場合(戻るボタン以外不能)  N:正常
   ***************************************************************************
   */
  public void itemControl(String errFlag)
  {
    // PVO取得
    OAViewObject pvo = getXxwshShipLotInputPVO1();   
    // PVO1行目を取得
    OARow pvoRow = (OARow)pvo.first();
    // デフォルト値設定
    pvoRow.setAttribute("ReturnRendered",          Boolean.TRUE); // 支給支持画面へ戻る：表示
    pvoRow.setAttribute("CheckRendered",           Boolean.TRUE); // チェック：表示
    pvoRow.setAttribute("AddRowRendered",          Boolean.TRUE); // 行挿入：表示
    pvoRow.setAttribute("GoDisabled",              Boolean.FALSE);// 適用：有効
    pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.FALSE);// 数量：有効

    // エラーの場合(戻るボタン以外制御不能)
    if (XxcmnConstants.STRING_Y.equals(errFlag))
    {
      pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // チェック：非表示
      pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // 行挿入：非表示
      pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // 適用：無効
      pvoRow.setAttribute("ReturnRendered",          Boolean.FALSE); // 支給支持画面へ戻る：非表示
      pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // 数量：無効

    // エラーでない場合      
    } else
    {
      // 明細VO取得
      OAViewObject lineVo = getXxwshLineVO1();
      // 明細1行目を取得
      OARow lineRow   = (OARow)lineVo.first();
      // 値取得
      String reqStatus          = (String)lineRow.getAttribute("ReqStatus");          // ステータス
      String amountFixClass     = (String)lineRow.getAttribute("AmountFixClass");     // 有償金額確定区分
      String shipSupplyCategory = (String)lineRow.getAttribute("ShipSupplyCategory"); // 出荷支給受払カテゴリ
      String lotCtl             = (String)lineRow.getAttribute("LotCtl");             // ロット管理区分
      String callPictureKbn     = (String)lineRow.getAttribute("CallPictureKbn");     // 呼出画面区分
      String recordTypeCode     = (String)lineRow.getAttribute("RecordTypeCode");     // レコードタイプ

      // レコードタイプが20:出庫実績の場合
      if (XxwshConstants.RECORD_TYPE_DELI.equals(recordTypeCode))
      {
        // 呼出画面区分が1:出荷依頼入力画面の場合
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
        {
          pvoRow.setAttribute("ReturnRendered", Boolean.FALSE); // 支給支持画面へ戻る：非表示

        // 以下のいづれかの場合
        // * ・呼出画面区分が2:支給指示作成画面
        // * ・呼出画面区分が5:入庫実績画面
        // * ・出荷支給受払カテゴリが05:有償出荷かつ、有償金額確定区分が1:確定
        // * ・出荷支給受払カテゴリが06:有償返品かつ、ステータスが08:出荷実績計上済
        } else if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn)  
            || XxwshConstants.CALL_PIC_KBN_STOC.equals(callPictureKbn)
            || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP.equals(shipSupplyCategory)
              && XxwshConstants.AMOUNT_FIX_CLASS_Y.equals(amountFixClass))
            || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_RET.equals(shipSupplyCategory) 
              && XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus)))
        {
          pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // チェック：非表示
          pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // 行挿入：非表示
          pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // 適用：無効
          pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // 数量：無効

          lineRow.setAttribute("UpdateFlg",     XxcmnConstants.STRING_N); // 更新区分：N
        }

      // レコードタイプが30：入庫実績の場合
      } else
      {
        // 以下のいづれかの場合
        // * ・呼出画面区分が2:支給指示作成画面
        // * ・呼出画面区分が4:出庫実績画面
        // * ・出荷支給受払カテゴリが05:有償出荷かつ、有償金額確定区分が1:確定
        // * ・出荷支給受払カテゴリが06:有償返品かつ、ステータスが08:出荷実績計上済 
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn)
          || XxwshConstants.CALL_PIC_KBN_DELI.equals(callPictureKbn)
          || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP.equals(shipSupplyCategory)
            && XxwshConstants.AMOUNT_FIX_CLASS_Y.equals(amountFixClass))
          || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_RET.equals(shipSupplyCategory)
            && XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus)))
        {
          pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // チェック：非表示
          pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // 行挿入：非表示
          pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // 適用：無効
          pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // 数量：無効

          lineRow.setAttribute("UpdateFlg",     XxcmnConstants.STRING_N); // 更新区分：N
        }
      }

      // ロット管理外品の場合
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
      {
        pvoRow.setAttribute("CheckRendered",  Boolean.FALSE); // チェック：非表示
        pvoRow.setAttribute("AddRowRendered", Boolean.FALSE); // 行挿入：非表示
      }      
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
    HashMap ret = new HashMap();
    ret.put("orderLineId",        lineRow.getAttribute("OrderLineId"));           // 受注明細アドオンID
    ret.put("documentTypeCode",   lineRow.getAttribute("DocumentTypeCode"));      // 文書タイプ
    ret.put("recordTypeCode",     lineRow.getAttribute("RecordTypeCode"));        // レコードタイプ
    ret.put("itemId",             lineRow.getAttribute("OpmItemId"));             // 品目ID
    ret.put("itemCode",           lineRow.getAttribute("ItemCode"));              // 品目コード
    ret.put("prodClassCode",      lineRow.getAttribute("ProdClassCode"));         // 商品区分
    ret.put("itemClassCode",      lineRow.getAttribute("ItemClassCode"));         // 品目区分
    ret.put("lotId",              resultLotRow.getAttribute("LotId"));            // ロットID
    ret.put("lotNo",              resultLotRow.getAttribute("LotNo"));            // ロットNo
    ret.put("manufacturedDate",   resultLotRow.getAttribute("ManufacturedDate")); // 製造年月日
    ret.put("useByDate",          resultLotRow.getAttribute("UseByDate"));        // 賞味期限
    ret.put("koyuCode",           resultLotRow.getAttribute("KoyuCode"));         // 固有記号
    
    String recordTypeCode = (String)lineRow.getAttribute("RecordTypeCode");
    // レコードタイプが20:出庫実績の場合
    if (XxwshConstants.RECORD_TYPE_DELI.equals(recordTypeCode))
    {
      ret.put("actualDate",         lineRow.getAttribute("ShippedDate"));         // 実績日 = 出荷日

    //  処理モードが2：入庫実績の場合
    } else
    {
      ret.put("actualDate",         lineRow.getAttribute("ArrivalDate"));         // 実績日 = 着荷日
    }

    // 実績数量取得
    // 換算数量が正しい数値でない場合は、NULL
    String convertQuantity = (String)resultLotRow.getAttribute("ConvertQuantity");
    Number numOfCases      = (Number)lineRow.getAttribute("NumOfCases");
    if (!XxcmnUtility.isBlankOrNull(convertQuantity)
      && XxcmnUtility.chkNumeric(convertQuantity, 9, 3)
      && XxcmnUtility.chkCompareNumeric(2, convertQuantity, "0"))
    {
      ret.put("actualQuantity", Double.toString(doConversion(convertQuantity, numOfCases)));  

    } else
    {
      ret.put("actualQuantity", "");
    }

    return ret;
  }

  /***************************************************************************
   * チェックボタン押下処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void checkLot() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    HashMap data = new HashMap();

    String apiName   = "checkLot";
    
    // 明細VO取得
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    String callPictureKbn     = (String)lineRow.getAttribute("CallPictureKbn" );    // 呼出画面区分
    String locationRelCode    = (String)lineRow.getAttribute("LocationRelCode");    // 拠点実績有無区分
    String shipSupplyCategory = (String)lineRow.getAttribute("ShipSupplyCategory"); // 出荷支給受払カテゴリ
    String lotCtl             = (String)lineRow.getAttribute("LotCtl");             // ロット管理区分
    String itemClassCode      = (String)lineRow.getAttribute("ItemClassCode");      // 品目区分
// 2008-09-25 H.Itou Add Start ロットステータスチェック実施判断のため、在庫調整区分取得
    String adjsClass          = (String)lineRow.getAttribute("AdjsClass" );         // 在庫調整区分
// 2008-09-25 H.Itou Add End
      
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    OARow resultLotRow = null;
    // 1行目
    resultLotVo.first();

    // ロット管理区分が1：ロット管理品の場合のみチェックを行う。
    if (XxwshConstants.LOT_CTL_Y.equals(lotCtl))
    {
      // 全件ループ
      while (resultLotVo.getCurrentRow() != null)
      {
        // 処理対象行を取得
        resultLotRow = (OARow)resultLotVo.getCurrentRow();

        // ********************************** // 
        // *   チェック実施レコード判定     * //
        // ********************************** //         
        // 製品の場合
        if(XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
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
      
        // 実績ロットデータHashMap取得
        data = getResultLotHashMap(resultLotRow, lineRow);

        // ********************************** // 
        // *   ロットマスタ妥当性チェック   * //
        // ********************************** //     
        XxwshUtility.seachOpmLotMst(getOADBTransaction(), data);
        // 値取得
        String statusDesc       = (String)data.get("statusDesc");       // ステータスコード名称
        String payProvisionRel  = (String)data.get("payProvisionRel");  // 有償支給(実績)
        String shipReqRel       = (String)data.get("shipReqRel");       // 出荷依頼(実績)
        String retCode          = (String)data.get("retCode");          // 戻り値
        String lotNo            = (String)data.get("lotNo");            // ロットNo
        String koyuCode         = (String)data.get("koyuCode");         // 固有記号
        Number lotId            = (Number)data.get("lotId");            // ロットID
        Date   manufacturedDate = null;
        Date   useByDate        = null;
        try
        {       
          if (!XxcmnUtility.isBlankOrNull(data.get("manufacturedDate")))
          {
            manufacturedDate = new Date(data.get("manufacturedDate")); // 製造年月日          
          }
          if (!XxcmnUtility.isBlankOrNull(data.get("useByDate")))
          {
            useByDate = new Date(data.get("useByDate")); // 賞味期限          
          }

        // SQL例外の場合
        } catch(SQLException s)
        {
            // ロールバック
            XxwshUtility.rollBack(getOADBTransaction());
            // ログ出力
            XxcmnUtility.writeLog(
              getOADBTransaction(),
              XxwshConstants.CLASS_AM_XXWSH920001J + XxcmnConstants.DOT + apiName,
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
          // エラーメッセージ用に取得しなおし。
          lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ロットNo
          // ロット情報取得エラー
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "LotNo",
                  lotNo,
                  XxcmnConstants.APPL_XXWSH, 
                  XxwshConstants.XXWSH13312));
                
          // 後続処理を行わずに、次のレコード処理
          resultLotVo.next();
          continue;
        }

        // ********************************** // 
        // *   ロットステータスチェック     * //
        // ********************************** //
        String actualQuantity = (String)data.get("actualQuantity"); // 換算数量
        double actualQuantityD = 0;
        // 数量が入力されている場合は、数量をdouble型に変換
        if (!XxcmnUtility.isBlankOrNull(actualQuantity))
        {
          actualQuantityD = Double.parseDouble(actualQuantity);// 換算実績数量                    
        }

        // 換算数量に値のない場合または、換算実績数量が0でない場合はロットステータスチェックを行う。
        if (XxcmnUtility.isBlankOrNull(actualQuantity) || (actualQuantityD != 0))
        {
          // 呼出画面区分が1:出荷依頼入力画面かつ、拠点実績有無区分が1:売上拠点かつ、出荷依頼(実績)がN:対象外の場合
          if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
            && XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(locationRelCode)
// 2008-09-25 H.Itou Add Start 在庫調整区分が2の場合はロットステータスエラーとしない
            && !XxwshConstants.ADJS_CLASS_2.equals(adjsClass)
// 2008-09-25 H.Itou Add End
            && XxcmnConstants.STRING_N.equals(shipReqRel))
          {
            // ロットステータスエラー
            // エラーメッセージトークン取得
            MessageToken[] tokens = {new MessageToken(XxwshConstants.TOKEN_LOT_STATUS, statusDesc)};      
            // エラーメッセージ取得                            
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13301,
                    tokens));
                
            // 後続処理を行わずに、次のレコード処理
            resultLotVo.next();
            continue;
          }

          // 呼出画面区分が1:出荷依頼入力画面以外かつ、出荷受払カテゴリが05:有償出荷で、有償支給(実績)がN:対象外の場合
          if (!XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
            && XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP.equals(shipSupplyCategory)
            && XxcmnConstants.STRING_N.equals(payProvisionRel))
          {
            // ロットステータスエラー
            // エラーメッセージトークン取得
            MessageToken[] tokens = {new MessageToken(XxwshConstants.TOKEN_LOT_STATUS, statusDesc)};      
            // エラーメッセージ取得                            
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13301,
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
          OAViewObject vo  = getXxwshResultLotVO1();
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
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13305));
                  
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
   * @return String - 0:処理対象行なし 1:処理対象行あり
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String checkError() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    HashMap date = new HashMap();
    String entryFlag = "0"; // 処理対象フラグ

    // 明細VO取得
    OAViewObject lineVo   = getXxwshLineVO1();
    OARow        lineRow  = (OARow)lineVo.first();
    String itemClassCode  = (String)lineRow.getAttribute("ItemClassCode");  // 品目区分
    String lotCtl         = (String)lineRow.getAttribute("LotCtl");         // ロット管理区分
    String recordTypeCode = (String)lineRow.getAttribute("RecordTypeCode"); // レコードタイプ

    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxwshResultLotVO1();
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
      if (XxwshConstants.LOT_CTL_Y.equals(lotCtl))
      {
         // 品目区分が5:製品の場合
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
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
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
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
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
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
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
          }

        // 品目区分が5:製品以外の場合 
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
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
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
                XxcmnConstants.APPL_XXWSH, 
                XxwshConstants.XXWSH13302));
                
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
                  XxcmnConstants.APPL_XXWSH,         
                  XxwshConstants.XXWSH13313));

        // マイナス値はエラー
        } else if(!XxcmnUtility.chkCompareNumeric(2, convertQuantity, "0"))
        {
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "ConvertQuantity",
                  convertQuantity,
                  XxcmnConstants.APPL_XXWSH,         
                  XxwshConstants.XXWSH13303));
        }
      }

      // 処理対象フラグON
      entryFlag = "1";
      
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
    // レコードタイプが20:出庫実績の場合、出荷日で在庫クローズチェック
    if (XxwshConstants.RECORD_TYPE_DELI.equals(recordTypeCode))
    {
      Date shippedDate = (Date)lineRow.getAttribute("ShippedDate"); // 出荷日
      XxwshUtility.chkStockClose(getOADBTransaction(), shippedDate);
// 2008-10-17 H.Itou Add Start 統合テスト指摘346
    // レコードタイプが30:入庫実績の場合、着荷日で在庫クローズチェック
    } else 
    {
      Date arrivalDate = (Date)lineRow.getAttribute("ArrivalDate"); // 着荷日
      XxwshUtility.chkStockClose(getOADBTransaction(), arrivalDate);
// 2008-10-17 H.Itou Add End
    }

    return entryFlag;
  }

  /***************************************************************************
   * 依頼Noを取得するメソッドです。
   * @param orderLineId  - 受注明細アドオンID
   * @return String      - 依頼No
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String getReqNo(String orderLineId) throws OAException
  {   
    return XxwshUtility.getRequestNo(getOADBTransaction(), orderLineId);
  }

  /***************************************************************************
   * 警告チェックを行うメソッドです。
   * @return HashMap     - 警告エラー情報
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap checkWarning() throws OAException
  {
    HashMap msg = new HashMap();

    // 明細VO取得
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    String orderCategoryCode = (String)lineRow.getAttribute("OrderCategoryCode");// 受注カテゴリ
    String callPictureKbn    = (String)lineRow.getAttribute("CallPictureKbn");   // 呼出画面区分
    Number orderLineId       = (Number)lineRow.getAttribute("OrderLineId");      // 受注明細アドオンID
    Number opmItemId         = (Number)lineRow.getAttribute("OpmItemId");        // OPM品目ID
    String itemCode          = (String)lineRow.getAttribute("ItemCode");         // 品目コード
    String itemName          = (String)lineRow.getAttribute("ItemName");         // 品目名
    Number numOfCases        = (Number)lineRow.getAttribute("NumOfCases");       // ケース入数
    String reqStatus         = (String)lineRow.getAttribute("ReqStatus");        // ステータス
    String prodClassCode     = (String)lineRow.getAttribute("ProdClassCode");    // 商品区分
    String itemClassCode     = (String)lineRow.getAttribute("ItemClassCode");    // 品目区分
    String resultDeliverTo   = (String)lineRow.getAttribute("ResultDeliverTo");  // 出荷先(コード)
    String subinventoryName  = (String)lineRow.getAttribute("SubinventoryName"); // 保管倉庫名
    Number resultDeliverToId = (Number)lineRow.getAttribute("ResultDeliverToId");// 出荷先_実績ID
    Number deliverFromId     = (Number)lineRow.getAttribute("DeliverFromId");    // 出荷元ID
    Date   shippedDate       = (Date)  lineRow.getAttribute("ShippedDate");      // 出荷日
    Date   scheduleShipDate  = (Date)  lineRow.getAttribute("ScheduleShipDate"); // 出荷予定日
    String documentTypeCode  = (String)lineRow.getAttribute("DocumentTypeCode"); // 文書タイプ
    String recordTypeCode    = (String)lineRow.getAttribute("RecordTypeCode");   // レコードタイプ
    String lotCtl            = (String)lineRow.getAttribute("LotCtl");           // ロット管理区分
        
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    OARow resultLotRow = null;

    // 警告情報格納用
    String[]  lotRevErrFlgRow = new String[resultLotVo.getRowCount()]; // ロット逆転防止チェックエラーフラグ
    String[]  minusErrFlgRow  = new String[resultLotVo.getRowCount()]; // マイナス在庫チェックエラーフラグ   
    String[]  exceedErrFlgRow = new String[resultLotVo.getRowCount()]; // 引当可能在庫数超過チェックエラーフラグ   
    String[]  itemNameRow     = new String[resultLotVo.getRowCount()]; // 品目名
    String[]  lotNoRow        = new String[resultLotVo.getRowCount()]; // ロットNo
    String[]  deliveryRow     = new String[resultLotVo.getRowCount()]; // 出荷先(コード)
    String[]  revDateRow      = new String[resultLotVo.getRowCount()]; // 逆転日付
    String[]  manuDateRow     = new String[resultLotVo.getRowCount()]; // 製造年月日
    String[]  koyuCodeRow     = new String[resultLotVo.getRowCount()]; // 固有記号
    String[]  stockRow        = new String[resultLotVo.getRowCount()]; // 手持数量
    String[]  warehouseRow    = new String[resultLotVo.getRowCount()]; // 保管倉庫名

    // 1行目
    resultLotVo.first();

    // 受注カテゴリがORDER:受注の場合のみ警告チェックを行う。
    if (XxwshConstants.ORDER_CATEGORY_CODE_ORDER.equals(orderCategoryCode))
    {
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
        lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // ロット逆転防止チェックエラーフラグ
        minusErrFlgRow [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // マイナス在庫チェックエラーフラグ 
        exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // 引当可能在庫数超過チェックエラーフラグ   
        itemNameRow    [resultLotVo.getCurrentRowIndex()] = itemName;         // 品目名
        lotNoRow       [resultLotVo.getCurrentRowIndex()] = lotNo;            // ロットNo
        deliveryRow    [resultLotVo.getCurrentRowIndex()] = resultDeliverTo;  // 出荷先名称
        revDateRow     [resultLotVo.getCurrentRowIndex()] = "";               // 逆転日付
        manuDateRow    [resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(manufacturedDate); // 製造年月日
        koyuCodeRow    [resultLotVo.getCurrentRowIndex()] = koyuCode;         // 固有記号
        stockRow       [resultLotVo.getCurrentRowIndex()] = "";               // 手持数量
        warehouseRow   [resultLotVo.getCurrentRowIndex()] = subinventoryName; // 保管倉庫名     

        // *************************** //
        // *  ロット逆転防止チェック * //
        // *************************** //
        // 呼出画面区分が1:出荷依頼入力画面かつ、ロット管理区分が1：ロット管理品の場合のみ
        // ロット逆転防止チェックを行う。
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
          && XxwshConstants.LOT_CTL_Y.equals(lotCtl))
        {
          // * 以下の条件に当てはまる場合、チェックを行う。
          // * ・ステータスが03:締め済
          // * ・(商品区分が2:ドリンクかつ、品目区分が5:製品) または 
          // *   (商品区分が1:リーフかつ、品目区分が(4:半製品 または 5:製品))
          // * ・製造年月日がNULLでない
          if (XxwshConstants.TRANSACTION_STATUS_CLOSE.equals(reqStatus)
            && (XxwshConstants.PROD_CLASS_CODE_DRINK.equals(prodClassCode)
                && XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
              || (XxwshConstants.PROD_CLASS_CODE_LEAF .equals(prodClassCode)
                && (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode)
                  || XxwshConstants.ITEM_TYPE_HALF.equals(itemClassCode)))
            && !XxcmnUtility.isBlankOrNull(manufacturedDate))
          {
            // ロット逆転防止チェック
            HashMap data = XxwshUtility.doCheckLotReversal(
                            getOADBTransaction(),
                            itemCode,
                            lotNo,
                            resultDeliverToId,
                            shippedDate);

            Number result  = (Number)data.get("result");  // 処理結果
            Date   revDate = (Date)  data.get("revDate"); // 逆転日付

            // API実行結果が1:エラーの場合
            if (XxwshConstants.RETURN_NOT_EXE.equals(result))
            {
              // ロット逆転防止エラーフラグをYに設定
              lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
              revDateRow[resultLotVo.getCurrentRowIndex()]      = XxcmnUtility.stringValue(revDate); // 逆転日付
            }
          }
        }

        // ******************************** //
        // * 手持在庫数量・引当可能数取得 * //
        // ******************************** //
        // 手持在庫数量算出API実行
        Number stockQyt = XxwshUtility.getStockQty(
                            getOADBTransaction(),
                            deliverFromId,
                            opmItemId,
                            lotId,
                            lotCtl);
        // 警告エラー用
        stockRow[resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(stockQyt); // 手持数量
        
        // 引当可能数算出API実行
        Number canEncQty = XxwshUtility.getCanEncQty(
                             getOADBTransaction(),
                             deliverFromId,
                             opmItemId,
                             lotId,
                             lotCtl);

        double stockQtyD       = XxcmnUtility.doubleValue(stockQyt);        // 手持在庫数量
        double canEncQtyD      = XxcmnUtility.doubleValue(canEncQty);       // 引当可能数
        double actualQtyInputD = doConversion(convertQuantity, numOfCases); // 実績数量(入力値)
        
        // ステータスが04:出荷実績計上済または、08:出荷実績計上済 の場合
        if (XxwshConstants.TRANSACTION_STATUS_ADD.equals(reqStatus)
          || XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus))
        {
          double resultActualQtyD = 0;
          // 実績ロットがある場合は、登録済実績ロットを取得
          if (XxwshUtility.checkMovLotDtl(
                getOADBTransaction(),
                orderLineId,           // 受注明細アドオンID
                documentTypeCode,      // 文書タイプ
                recordTypeCode,        // レコードタイプ
                lotId))                // ロットID
          {
            // 実績数量(実績ロット)取得
            resultActualQtyD = XxcmnUtility.doubleValue(
                                 XxwshUtility.getActualQuantity(
                                   getOADBTransaction(),
                                   orderLineId,           // 受注明細アドオンID
                                   documentTypeCode,      // 文書タイプ
                                   recordTypeCode,        // レコードタイプ
                                   lotId));               // ロットID
          }

          // 実績数量(実績ロット) < 実績数量(入力値) (登録済実績数量より多く登録する場合)のみチェック行う
          if (resultActualQtyD < actualQtyInputD)
          {
            // *************************** //
            // *   マイナス在庫チェック  * //
            // *************************** //
            // 手持在庫数量 - (実績数量(入力値) - 実績数量(実績ロット))が0より小さくなる場合、警告
            if ((stockQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
            {
              // マイナス在庫チェックエラーフラグをYに設定
              minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;              
            }
            // ********************************* //
            // *   引当可能在庫数超過チェック  * //
            // ********************************* //
            // 引当可能数 - (実績数量(入力値) - 実績数量(実績ロット))が0より小さくなる場合、警告
            if ((canEncQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
            {
              // 引当可能在庫数超過チェックエラーフラグをYに設定
              exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
            }
          }
          
        // ステータスが04:出荷実績計上済または、08:出荷実績計上済でない場合
        } else
        {
          // *************************** //
          // *   マイナス在庫チェック  * //
          // *************************** //
          // 手持在庫数量 - 実績数量(入力値) が0より小さくなる場合
          if ((stockQtyD - actualQtyInputD) < 0)
          {
            // マイナス在庫チェックエラーフラグをYに設定
            minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }

          // ********************************* //
          // *   引当可能在庫数超過チェック  * //
          // ********************************* //
          // 指示ロットがある場合
          if (XxwshUtility.checkMovLotDtl(
                getOADBTransaction(),
                orderLineId,                     // 受注明細アドオンID
                documentTypeCode,                // 文書タイプ
                XxwshConstants.RECORD_TYPE_INST, // レコードタイプ 10:指示
                lotId))                          // ロットID
          {
            // 実績数量(指示ロット)取得
            double indicateActualQtyD = XxcmnUtility.doubleValue(
                                           XxwshUtility.getActualQuantity(
                                             getOADBTransaction(),
                                             orderLineId,                     // 受注明細アドオンID
                                             documentTypeCode,                // 文書タイプ
                                             XxwshConstants.RECORD_TYPE_INST, // レコードタイプ 10:指示
                                             lotId));                         // ロットID

            // * 以下の条件すべてに当てはまる場合
            // * ・出荷予定日 > 出荷日 (前倒しで出荷した場合)
            // * ・引当可能数 - 実績数量(入力値) が0より小さくなる場合 
            if (XxcmnUtility.chkCompareDate(1, scheduleShipDate, shippedDate)
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
        }
        // 次のレコードへ
        resultLotVo.next();
      }
    } 
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow); // ロット逆転防止チェックエラーフラグ
    msg.put("minusErrFlg",      (String[])minusErrFlgRow);  // マイナス在庫チェックエラーフラグ 
    msg.put("exceedErrFlg",     (String[])exceedErrFlgRow); // 引当可能在庫数超過チェックエラーフラグ
    msg.put("itemName",         (String[])itemNameRow);     // 品目名
    msg.put("lotNo",            (String[])lotNoRow);        // ロットNo
    msg.put("delivery",         (String[])deliveryRow);     // 出荷先(コード)
    msg.put("revDate",          (String[])revDateRow);      // 逆転日付
    msg.put("manufacturedDate", (String[])manuDateRow);     // 製造年月日
    msg.put("koyuCode",         (String[])koyuCodeRow);     // 固有記号
    msg.put("stock",            (String[])stockRow);        // 手持数量
    msg.put("warehouseName",    (String[])warehouseRow);    // 保管倉庫名

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
   * 出荷実績ロットの登録処理を行うメソッドです。
   * @throws OAException - OA例外
   ****************************************************************************/
  public void entryShipData() throws OAException
  {    
    // ***************************** //
    // *  ロック取得・排他チェック * //
    // ***************************** //
    getLockAndChkExclusive();

    // 明細VO取得
    OAViewObject lineVo     = getXxwshLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();
    Number orderHeaderId    = (Number)lineRow.getAttribute("OrderHeaderId");
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");
    Number orderLineNumber  = (Number)lineRow.getAttribute("OrderLineNumber"); // 明細No
    String reqStatus        = (String)lineRow.getAttribute("ReqStatus");       // ステータス
    String requestNo        = (String)lineRow.getAttribute("RequestNo");       // 依頼No
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");// 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");  // レコードタイプ
    String callPictureKbn   = (String)lineRow.getAttribute("CallPictureKbn");  // 呼出画面区分
    String exeKbn           = (String)lineRow.getAttribute("ExeKbn");          // 起動区分
// 2008-07-23 H.Itou ADD START
    String actualConfirmClass = (String)lineRow.getAttribute("ActualConfirmClass"); // 実績計上済区分
// 2008-07-23 H.Itou ADD END
    Number newOrderHeaderId = null;
    Number newOrderLineId   = null;

    String actualQtySum = null;

    // ステータスが04 出荷実績計上済 OR 08 出荷実績計上済 の場合
// 2009-03-04 H.Iida MOD START 「ヘッダに紐付く出荷実績数量がすべて登録済の場合」の条件を削除
//// 2008-06-13 H.Itou MOD START 04 出荷実績計上済かつ、ヘッダに紐付く出荷実績数量がすべて登録済の場合に変更
//    if ((XxwshConstants.TRANSACTION_STATUS_ADD.equals(reqStatus)
//      && XxwshUtility.checkShippedQuantityEntry(getOADBTransaction(), orderHeaderId))
//// 2008-06-13 H.Itou MOD END
    if (XxwshConstants.TRANSACTION_STATUS_ADD.equals(reqStatus)
// 2009-03-04 H.Iida MOD END
      || XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus))
    {
// 2008-07-23 H.Itou ADD START
      // 実績計上済区分がYの場合のみ、コピー処理実行
      if (XxcmnConstants.STRING_Y.equals(actualConfirmClass))
      {
// 2008-07-23 H.Itou ADD END
// 2008-07-23 H.Itou MOD START
        // ************************* //
        // *  受注情報コピー処理   * //
        // ************************* //
        // 実績がすでに計上済なので、履歴を残すため、コピーする。
        newOrderHeaderId = XxwshUtility.copyOrderData(
                             getOADBTransaction(),
                             orderHeaderId);      

        // **************************** //
        // *  最新受注明細ID取得処理  * //
        // **************************** //
        newOrderLineId = XxwshUtility.getOrderLineId(
                           getOADBTransaction(),
                           newOrderHeaderId,
                           orderLineNumber);

        lineRow.setAttribute("OrderHeaderId", newOrderHeaderId); // 最新の受注ヘッダアドオンID
        lineRow.setAttribute("OrderLineId",   newOrderLineId);   // 最新の受注明細アドオンID

// 2008-07-23 H.Itou MOD END
// 2008-07-23 H.Itou ADD START
      // 実績計上済区分がYでない場合
      } else
      {
        // コピー処理をしないので、IDは変更なし
        newOrderHeaderId = orderHeaderId;
        newOrderLineId   = orderLineId;
      }
// 2008-07-23 H.Itou ADD END
      
      // ******************************** //
      // *  移動ロット詳細実績登録処理  * //
      // ******************************** //
      insertResultLot();

      // ********************** // 
      // *  実績数量合計取得  * //
      // ********************** //
      actualQtySum = XxwshUtility.getActualQuantitySum(
                       getOADBTransaction(),
                       newOrderLineId,
                       documentTypeCode,
                       recordTypeCode);
      
      // ****************************************** // 
      // *  受注明細アドオン出荷実績数量更新処理  * //
      // ****************************************** //
      XxwshUtility.updateShippedQuantity(
        getOADBTransaction(),
        newOrderLineId,
        actualQtySum);

// 2014-11-11 K.kiriu Add Start
      // ****************************************** // 
      // *  ロット情報保持マスタ作成更新処理      * //
      // ****************************************** //
      insertHoldLot();
// 2014-11-11 K.kiriu Add End
      
      // *********************** // 
      // *  出荷実績計上処理   * //
      // *********************** //
      doShippedResultAdd(requestNo, callPictureKbn);
      
    //ステータスが04 出荷実績計上済 OR 08 出荷実績計上済 以外の場合
    } else
    {    
      // ******************************** //
      // *  移動ロット詳細実績登録処理  * //
      // ******************************** //
      insertResultLot();

      // ********************** // 
      // *  実績数量合計取得  * //
      // ********************** //
      actualQtySum = XxwshUtility.getActualQuantitySum(
                       getOADBTransaction(),
                       orderLineId,
                       documentTypeCode,
                       recordTypeCode);
                     
      // ****************************************** // 
      // *  受注明細アドオン出荷実績数量更新処理  * //
      // ****************************************** //
      XxwshUtility.updateShippedQuantity(
        getOADBTransaction(),
        orderLineId,
        actualQtySum);

// 2014-11-11 K.kiriu Add Start
      // ****************************************** // 
      // *  ロット情報保持マスタ作成更新処理      * //
      // ****************************************** //
      insertHoldLot();
// 2014-11-11 K.kiriu Add End

      // 受注明細アドオンの出荷実績数量がすべて登録済の場合
      if (XxwshUtility.checkShippedQuantityEntry(getOADBTransaction(), orderHeaderId))
      {       
        // ****************************************** // 
        // *  受注ヘッダアドオンステータス更新処理  * //
        // ****************************************** //
        updateReqStatusAdd(orderHeaderId, callPictureKbn);

        // *********************** // 
        // *  出荷実績計上処理   * //
        // *********************** //
        doShippedResultAdd(requestNo, callPictureKbn);

      }
      
      // コピー処理をしないので、IDは変更なし
      newOrderHeaderId = orderHeaderId;
      newOrderLineId   = orderLineId;
    }

    // ***************** //
    // *  コミット     * //
    // ***************** //
    XxwshUtility.commit(getOADBTransaction());
      
    // ******************** // 
    // *  最終更新日入替  * //
    // ******************** //
    // 受注ヘッダ最終更新日取得
    String headerUpdateDate = XxwshUtility.getOrderHeaderUpdateDate(
                                getOADBTransaction(),
                                newOrderHeaderId);
    // 受注明細最終更新日取得
    String lineUpdateDate   = XxwshUtility.getOrderLineUpdateDate(
                                getOADBTransaction(),
                                newOrderHeaderId);

    // ******************** // 
    // *  再表示          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("orderLineId",      XxcmnUtility.stringValue(newOrderLineId));
    params.put("callPictureKbn",   callPictureKbn);
    params.put("headerUpdateDate", headerUpdateDate);
    params.put("lineUpdateDate",   lineUpdateDate);
    params.put("exeKbn",           exeKbn);
    params.put("recordTypeCode",   recordTypeCode);
    initialize(params);

    // **************************** // 
    // *  登録完了メッセージ出力  * //
    // **************************** //
    throw new OAException(
      XxcmnConstants.APPL_XXWSH,
      XxwshConstants.XXWSH33304, 
      null, 
      OAException.INFORMATION, 
      null);
    
  }

 /*****************************************************************************
   * 入庫実績ロットの登録処理を行うメソッドです。
   * @throws OAException - OA例外
   ****************************************************************************/
  public void entryStockData() throws OAException
  {    
    // ***************************** //
    // *  ロック取得・排他チェック * //
    // ***************************** //
    getLockAndChkExclusive();

    // 明細VO取得
    OAViewObject lineVo     = getXxwshLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();

    Number orderHeaderId    = (Number)lineRow.getAttribute("OrderHeaderId");     // 受注ヘッダアドオンID
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");       // 受注明細アドオンID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");  // 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");    // レコードタイプ
    String callPictureKbn   = (String)lineRow.getAttribute("CallPictureKbn");    // 呼出画面区分
    String exeKbn           = (String)lineRow.getAttribute("ExeKbn");            // 起動区分   
    String headerUpdateDate = (String)lineRow.getAttribute("HeaderUpdateDate");  // ヘッダ更新日
    
    String actualQtySum = null;

    // ******************************** //
    // *  移動ロット詳細実績登録処理  * //
    // ******************************** //
    insertResultLot();

    // ********************** // 
    // *  実績数量合計取得  * //
    // ********************** //
    actualQtySum = XxwshUtility.getActualQuantitySum(
                     getOADBTransaction(),
                     orderLineId,
                     documentTypeCode,
                     recordTypeCode);
                   
    // ****************************************** // 
    // *  受注明細アドオン入庫実績数量更新処理  * //
    // ****************************************** //
    XxwshUtility.updateShipToQuantity(
      getOADBTransaction(),
      orderLineId,
      actualQtySum);

    // ***************** //
    // *  コミット     * //
    // ***************** //
    XxwshUtility.commit(getOADBTransaction());
      
    // ******************** // 
    // *  最終更新日入替  * //
    // ******************** //
    // 受注明細最終更新日取得
    String lineUpdateDate   = XxwshUtility.getOrderLineUpdateDate(
                                getOADBTransaction(),
                                orderHeaderId);

    // ******************** // 
    // *  再表示          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("orderLineId",      XxcmnUtility.stringValue(orderLineId));
    params.put("callPictureKbn",   callPictureKbn);
    params.put("headerUpdateDate", headerUpdateDate);
    params.put("lineUpdateDate",   lineUpdateDate);
    params.put("exeKbn",           exeKbn);
    params.put("recordTypeCode",   recordTypeCode);
    initialize(params);

    // **************************** // 
    // *  登録完了メッセージ出力  * //
    // **************************** //
    throw new OAException(
      XxcmnConstants.APPL_XXWSH,
      XxwshConstants.XXWSH33304, 
      null, 
      OAException.INFORMATION, 
      null);
    
  }
  
 /*****************************************************************************
  * ロックを取得し、排他チェックを行うメソッドです。
  * @throws OAException - OA例外
  ****************************************************************************/
  public void getLockAndChkExclusive() throws OAException
  {
    // 明細VO取得
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    Number orderHeaderId    = (Number)lineRow.getAttribute("OrderHeaderId");    // 受注ヘッダアドオンID
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");      // 受注明細アドオンID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // レコードタイプ
    String headerUpdateDate = (String)lineRow.getAttribute("HeaderUpdateDate"); // ヘッダ更新日時
    String lineUpdateDate   = (String)lineRow.getAttribute("LineUpdateDate");   // 明細更新日時

    String retCode = null;
    String headerUpdateDateDb = null; // 受注ヘッダ最終更新日
    String lineUpdateDateDb   = null; // 受注明細最終更新日

    // ******************************** //
    // *   受注ヘッダアドオンロック   * //
    // ******************************** //
    HashMap orderHeaderRet = XxwshUtility.getXxwshOrderHeadersAllLock(
                               getOADBTransaction(),
                               orderHeaderId);
    retCode            = (String)orderHeaderRet.get("retFlag");        // 戻り値
    headerUpdateDateDb = (String)orderHeaderRet.get("lastUpdateDate"); // 最終更新日
    // ロックエラーの場合
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ロックエラーメッセージ出力
      throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH13306);
    }

    // ******************************** //
    // *   受注明細アドオンロック   * //
    // ******************************** //
    HashMap orderLineRet = XxwshUtility.getXxwshOrderLinesAllLock(
                             getOADBTransaction(),
                             orderHeaderId);
    retCode          = (String)orderLineRet.get("retFlag");        // 戻り値
    lineUpdateDateDb = (String)orderLineRet.get("lastUpdateDate"); // 最終更新日
    // ロックエラーの場合
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ロックエラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13306);
    }

    // *********************************** //
    // *  移動ロット詳細アドオンロック   * //
    // *********************************** //
    retCode = XxwshUtility.getXxinvMovLotDetailsLock(
                getOADBTransaction(),
                orderLineId,           // 受注明細アドオンID
                documentTypeCode,      // 文書タイプ
                recordTypeCode);       // レコードタイプ

    // ロックエラーの場合
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ロックエラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13306);
    }
    // ******************************** //
    // *   受注ヘッダ排他チェック     * //
    // ******************************** //
    // ロック時に取得した最終更新日と比較
    if (!headerUpdateDateDb.equals(headerUpdateDate))
    {
// 2008-06-27 H.Itou Mod Start
      // 自分自身のコンカレント起動により更新された場合は排他エラーとしない
      if (!XxwshUtility.isOrderHdrUpdForOwnConc(
             getOADBTransaction(),
             orderHeaderId,
             XxwshConstants.CONC_NAME_XXWSH420001C))
      {
        // ロールバック
        XxwshUtility.rollBack(getOADBTransaction());
        // 排他エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10147);        
      }
// 2008-06-27 H.Itou Mod End
    }

    // ******************************** //
    // *   受注明細排他チェック       * //
    // ******************************** //
    // ロック時に取得した最終更新日と比較
    if (!lineUpdateDateDb.equals(lineUpdateDate))
    {
// 2008-06-27 H.Itou Mod Start
      // 自分自身のコンカレント起動により更新された場合は排他エラーとしない
      if (!XxwshUtility.isOrderLineUpdForOwnConc(
             getOADBTransaction(),
             orderHeaderId,
             XxwshConstants.CONC_NAME_XXWSH420001C))
      {
        // ロールバック
        XxwshUtility.rollBack(getOADBTransaction());
        // 排他エラーメッセージ出力
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10147);       
      }
// 2008-06-27 H.Itou Mod End
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
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");      // 受注明細アドオンID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // 文書タイプ
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // レコードタイプ
      
    // 実績ロットVO取得
    OAViewObject resultLotVo = getXxwshResultLotVO1();
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
      if (XxwshUtility.checkMovLotDtl(
            getOADBTransaction(),
            orderLineId,           // 受注明細アドオンID
            documentTypeCode,      // 文書タイプ
            recordTypeCode,        // レコードタイプ
            lotId))                // ロットID
      {    
        // ******************************************** // 
        // *  移動ロット詳細アドオン実績数量更新処理  * //
        // ******************************************** //
        XxwshUtility.updateActualQuantity(getOADBTransaction(), data);
        
      // 実績ロットが登録済でない場合(実績新規時)
      } else
      {       
        // ************************************ // 
        // *  移動ロット詳細アドオン登録処理  * //
        // ************************************ //       
        XxwshUtility.insertXxinvMovLotDetails(getOADBTransaction(), data);          

      }
      // 次のレコードへ
      resultLotVo.next();
    }
  }
// 2014-11-11 K.kiriu Add Start
  /***************************************************************************
   * ロット情報保持マスタの実績登録、実績更新処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void insertHoldLot() throws OAException
  {

    // 明細VO取得
    OAViewObject lineVo      = getXxwshLineVO1();
    OARow        lineRow     = (OARow) lineVo.first();
    String lotCtl            = (String)lineRow.getAttribute("LotCtl");            // ロット管理区分
    String callPictureKbn    = (String)lineRow.getAttribute("CallPictureKbn");    // 呼出画面区分
    Number resultDeliverToId = (Number)lineRow.getAttribute("ResultDeliverToId"); // 出荷先_実績ID
    Number invItemId         = (Number)lineRow.getAttribute("InvItemId");         // 出荷品目ID
    Date   arrivalDate       = (Date)  lineRow.getAttribute("ArrivalDate");       // 着荷日
// 2015-03-27 K.kiriu Add Start
    String itemClassCode     = (String)lineRow.getAttribute("ItemClassCode");     // 品目区分
// 2015-03-27 K.kiriu Add End
    Number custId            = new Number();
    Number parentItemId      = new Number();
    String lotInfoCreateFlg  = XxcmnConstants.STRING_N;                           // ロット情報保持マスタ作成フラグ

    //ロット管理区分が1：ロット管理品の場合のみ実行
    if (XxwshConstants.LOT_CTL_Y.equals(lotCtl))
    {
      // 呼出画面区分が1:出荷依頼入力画面の場合のみ
      if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
      {
// 2015-03-27 K.kiriu Add Start
        // 品目区分が5:製品のみ
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
        {
// 2015-03-27 K.kiriu Add End
          // ************************************** // 
          // *  直送データの判定(顧客ID取得)処理  * //
          // ************************************** //
          custId = XxwshUtility.getCustID(getOADBTransaction(), resultDeliverToId);

          // 直送データの場合
          if (!custId.equals(XxwshConstants.NOT_DIRECT_CUST))
          {
            //ロット情報保持マスタ作成を作成する
            lotInfoCreateFlg = XxcmnConstants.STRING_Y;

            // システム日付を取得
            Date currentDate = getOADBTransaction().getCurrentDBDate();

            // ********************** //
            // *  親品目ID取得処理  * //
            // ********************** //
            parentItemId = XxwshUtility.getParentItemId(
                             getOADBTransaction(),
                             currentDate,   // システム日付
                             invItemId      // 出荷品目ID
                           );
          }
// 2015-03-27 K.kiriu Add Start
        }
// 2015-03-27 K.kiriu Add End
      }
      // 直送顧客、且つ、製品のみ実施
      if (lotInfoCreateFlg.equals(XxcmnConstants.STRING_Y))
      {
        // 実績ロットVO取得
        OAViewObject resultLotVo = getXxwshResultLotVO1();
        resultLotVo.first();
        OARow resultLotRow = null;

        // 全件ループ
        while (resultLotVo.getCurrentRow() != null)
        {
          resultLotRow            = (OARow)resultLotVo.getCurrentRow();
          Date   useByDate        = (Date)resultLotRow.getAttribute("UseByDate");          // 賞味期限
          String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // 換算実績数量
          double convertQuantityD = Double.parseDouble(convertQuantity);                   // 換算数量(取消判断用)
          String eSKbn            = XxcmnConstants.STRING_TWO;                             // 営業生産区分(生産)
          String cancelKbn        = new String();                                          // 取消区分

          // ロット情報保持マスタの追加・更新用HashMap取得
          HashMap lotData = new HashMap();

          // 数量が0(取消)の場合
          if (convertQuantityD != 0)
          {
            cancelKbn = XxcmnConstants.STRING_ZERO;  //取消区分0
          // 取消以外の場合
          } else
          {
            cancelKbn = XxcmnConstants.STRING_ONE;   //取消区分1
          }

          // パラメータの編集
          lotData.put("cutId",             custId);             // 顧客ID
          lotData.put("resultDeliverToId", resultDeliverToId);  // 出荷先ID_実績
          lotData.put("parentItemId",      parentItemId);       // 親品目ID
          lotData.put("deliverLot",        useByDate);          // 納品ロット(賞味期限)
          lotData.put("deliveryDate",      arrivalDate);        // 納品日(着荷日)
          lotData.put("eSKbn",             eSKbn);              // 営業生産区分
          lotData.put("cancelKbn",         cancelKbn);          // 取消区分

          // ****************************************** //
          // *  ロット情報保持マスタの追加・更新処理  * //
          // ****************************************** //
          XxwshUtility.insUpdLotHoldInfo(
            getOADBTransaction(),
            lotData
          );

          // 次のレコードへ
          resultLotVo.next();

        }
      }
    }
  }
// 2014-11-11 K.kiriu Add End

  /***************************************************************************
   * 受注ヘッダアドオンステータスを出荷実績計上済に更新するメソッドです。
   * @param  orderHeaderId   - 受注ヘッダアドオンID
   * @param  callPictureKbn  - 呼出画面区分
   * @throws OAException     - OA例外
   ***************************************************************************
   */
  public void updateReqStatusAdd(
    Number orderHeaderId,
    String callPictureKbn)
  throws OAException
  {
    String reqStatus = null; // ステータス
    
    // 呼出画面区分が1:出荷依頼入力画面の場合
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      reqStatus = XxwshConstants.TRANSACTION_STATUS_ADD; // ステータス 04 出荷実績計上済

    // それ以外の場合(支給画面)の場合
    } else
    {
      reqStatus = XxwshConstants.XXPO_TRANSACTION_STATUS_ADD; // ステータス 08 出荷実績計上済
    }

    XxwshUtility.updateReqStatus(
      getOADBTransaction(),
      orderHeaderId,
      reqStatus);
  }

  /***************************************************************************
   * 出荷実績計上処理(重量容積小口更新・出荷依頼/出荷実績作成)を行うメソッドです。
   * @param  requestNo         - 依頼No
   * @param  callPictureKbn    - 呼出画面区分
   * @throws OAException       - OA例外
   ***************************************************************************
   */
  public void doShippedResultAdd(
    String requestNo,
    String callPictureKbn)
  throws OAException
  {
    String reqStatus = null; // ステータス
    String bizType   = null; // 業務種別

    // 呼出画面区分が1:出荷依頼入力画面の場合
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      reqStatus = XxwshConstants.TRANSACTION_STATUS_ADD; // ステータス 04 出荷実績計上済
      bizType   = XxcmnConstants.BIZ_TYPE_WSH;           // 業務種別    1 出荷

    // それ以外の場合(支給画面)の場合
    } else
    {
      reqStatus = XxwshConstants.XXPO_TRANSACTION_STATUS_ADD; // ステータス 08 出荷実績計上済
      bizType = XxcmnConstants.BIZ_TYPE_PROV;                 // 業務種別    2 支給
    }
        
    // ********************************** // 
    // *  重量容積小口個数更新チェック  * //
    // ********************************** //
    Number ret = XxwshUtility.doUpdateLineItems(getOADBTransaction(), bizType, requestNo);
    // 重量容積小口更新関数の戻り値が1：エラーの場合
    if (XxwshConstants.RETURN_NOT_EXE.equals(ret))
    {
      // ロールバック
      XxwshUtility.rollBack(getOADBTransaction());
      // 重量容積小口個数更新関数エラーメッセージ出力
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13308);
    }

    // ***************** //
    // *  コミット     * //
    // ***************** //
    XxwshUtility.commit(getOADBTransaction());

    // *********************************************** // 
    // *  出荷依頼/出荷実績作成処理コンカレント呼出  * //
    // *********************************************** //
    XxwshUtility.doShipRequestAndResultEntry(getOADBTransaction(), requestNo);
  }

  /***************************************************************************
   * 空行扱いかどうかを判定するメソッドです。
   * @param  row         - 対象行
   * @return boolean     - true  : 入力項目がすべてNULL  false : 入力項目がNULLでない
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
    if ((XxcmnUtility.isBlankOrNull(lotNo))
      && (XxcmnUtility.isBlankOrNull(manufacturedDate))
      && (XxcmnUtility.isBlankOrNull(useByDate))
      && (XxcmnUtility.isBlankOrNull(koyuCode))
      && (XxcmnUtility.isBlankOrNull(convertQuantity)))
    {
      return true;

    // いづれかに入力ありの場合
    } else
    {
      return false;
    }
  }
  
  /**
   * 
   * Container's getter for XxwshLineVO1
   */
  public XxwshLineVOImpl getXxwshLineVO1()
  {
    return (XxwshLineVOImpl)findViewObject("XxwshLineVO1");
  }

  /**
   * 
   * Container's getter for XxwshIndicateLotVO1
   */
  public XxwshIndicateLotVOImpl getXxwshIndicateLotVO1()
  {
    return (XxwshIndicateLotVOImpl)findViewObject("XxwshIndicateLotVO1");
  }

  /**
   * 
   * Container's getter for XxwshResultLotVO1
   */
  public XxwshResultLotVOImpl getXxwshResultLotVO1()
  {
    return (XxwshResultLotVOImpl)findViewObject("XxwshResultLotVO1");
  }

  /**
   * 
   * Container's getter for XxwshShipLotInputPVO1
   */
  public XxwshShipLotInputPVOImpl getXxwshShipLotInputPVO1()
  {
    return (XxwshShipLotInputPVOImpl)findViewObject("XxwshShipLotInputPVO1");
  }


  
}