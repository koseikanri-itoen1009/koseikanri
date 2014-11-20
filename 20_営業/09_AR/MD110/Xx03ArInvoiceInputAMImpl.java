/*===========================================================================
 * Copyright (c) Oracle Corporation Japan, 2004-2005  All rights reserved
 * FILENAME   Xx03ArInvoiceInputAMImpl.java
 * VERSION    11.5.10.2.10E
 * DATE       2008/02/14
 * HISTORY    2004/12/17                   新規作成
 *            2005/02/24 ver 1.1           仕様変更対応組込
 *            2005/03/03 ver 1.2           不具合対応
 *            2005/03/18 ver 1.3           前受金の約定取引日チェック処理追加
 *                                         消費税自動計算の不具合修正
 *                                         支払方法の有効日チェック処理追加
 *            2005/03/25 ver 1.4           消費税自動計算の不具合修正
 *            2005/04/15 ver 11.5.10.1     コピー機能仕様変更対応組込
 *            2005/06/22 ver 11.5.10.1.3   消費税計算ロジックの不具合修正
 *            2005/07/25 ver 11.5.10.1.4   消費税端数計算ロジックの修正
 *            2005/08/04 ver 11.5.10.1.4B  明細が未入力のときに存在チェックが
 *                                         実施されない不具合の修正
 *            2005/08/05 ver 11.5.10.1.4C  入力金額算出不具合修正
 *            2005/08/10 ver 11.5.10.1.4D  コピー機能の不具合修正
 *            2005/09/07 ver 11.5.10.1.5   前受金と一見顧客入力に対応するために、
 *                                         11.5.10.1.4Bの修正を削除
 *            2005/09/27 ver 11.5.10.1.5B  税計算レベルと端数処理方法の情報を
 *                                         取得する際の不具合修正
 *            2005/11/11 ver 11.5.10.1.6   マスタ無効の過去データ表示対応
 *            2005/11/22 ver 11.5.10.1.6B  マスタ無効データ対応（一括承認）
 *            2005/12/08 ver 11.5.10.1.6C  伝票種別の有効チェック不備対応
 *            2005/12/19 ver 11.5.10.1.6D  承認者判定の修正対応
 *            2005/12/26 ver 11.5.10.1.6E  税区分の有効チェック対応
 *            2005/12/27 ver 11.5.10.1.6G  メニューから無効な伝票種別を選択した際の
 *                                         エラー対応
 *            2005/12/28 ver 11.5.10.1.6H  エラーメッセージの最大取得件数不具合対応
 *            2006/01/11 ver 11.5.10.1.6I  障害578 承認者判定の修正
 *            2006/01/16 ver 11.5.10.1.6J  件数の取得方法をgetFetchedRowCount()から
 *                                         getRowCount()に修正
 *            2006/01/19 ver 11.5.10.1.6K  消費税額が入力されていない場合も
 *                                         消費税額を算出するように修正
 *            2006/01/23 ver 11.5.10.1.6L  CommonUtilを利用した固定メッセージを
 *                                         メッセージテーブルから取得するよう変更
 *            2006/01/27 ver 11.5.10.1.6M  明細の最大件数チェック対応
 *            2006/01/30 ver 11.5.10.1.6N  checkConfValidation内で使用している
 *                                         イテレータselectUpdIterをメソッドの
 *                                         終了処理にてクローズするように修正
 *            2006/02/02 ver 11.5.10.1.6O  ボタンのダブルクリック対応
 *            2006/02/14 ver 11.5.10.1.6P  障害910税区分の日付絞込みをやめる
 *            2006/02/28 ver 11.5.10.1.6Q  一括承認時マスタチェックの処理変更
 *            2006/03/02 ver 11.5.10.1.6R  各タイミングでのマスタチェック統一
 *            2006/05/30 ver 11.5.10.2.3   部門移動時、本人作成伝票は検索できるように修正
 *            2006/08/22 ver 11.5.10.2.4   確認画面から申請時のチェックメソッド呼出方法修正
 *            2006/10/04 ver 11.5.10.2.6   マスタチェックの見直し(有効日のチェックを請求書日付で
 *                                         行なう項目とSYSDATEで行なう項目を再確認)
 *            2006/10/17 ver 11.5.10.2.6B  明細コピー後の画面表示をコピーした1行目の存在する
 *                                         ページとし、チェックボックスをクリアする
 *            2006/10/19 ver 11.5.10.2.6C  保存時のテンポラリコードをVOから取得するように変更
 *            2006/10/20 ver 11.5.10.2.6D  明細の入力チェック方法の誤り対応
 *                                         VOを取得して入力チェックするメソッド追加
 *            2006/10/23 ver 11.5.10.2.6E  重点管理チェックの誤り、申請時に再チェック
 *                                         するように修正(そのためのメソッド追加)
 *            2007/02/09 ver 11.5.10.2.7   伝票番号採番時にロックをかけていないため
 *                                         タイミングにより同一番号が発番される事の修正
 *            2007/08/28 ver 11.5.10.2.10  AR通貨有効日の比較対象は請求書日付とする修正
 *            2007/11/01 ver 11.5.10.2.10B 通貨の精度チェック(入力可能精度か桁チェック)追加のため
 *                                         通貨書式に丸める処理を削除
 *            2007/12/12 ver 11.5.10.2.10C 11.5.10.2.10Bでの仕様誤り
 *                                         単価×数量の結果は通貨書式に丸める処理を追加
 *            2008/01/08 ver 11.5.10.2.10D 端数処理の計算方法の変更(負数の端数処理時が
 *                                         PL/SQLと異なる結果となるためあわせるように修正)
 *            2008/02/14 ver 11.5.10.2.10E 消費税自動計算処理の時に請求書日付の入力チェックと
 *                                         税区分のマスタチェックを追加
 *            2008/11/10 ver 11.5.10.3     顧客のセキュリティチェック
 *===========================================================================*/
package oracle.apps.xx03.ar.input.server;
import com.sun.java.util.collections.Vector;

import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import java.util.ArrayList;
import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.xx03.util.Xx03ArCommonUtil;
import oracle.apps.fnd.framework.OANLSServices;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.Transaction;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import oracle.jbo.server.ViewLinkImpl;

// Ver1.3 add start --------------------------------------------
import java.math.BigDecimal;
// Ver1.3 add end ----------------------------------------------

//ver11.5.10.1.6 Add Start
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsVORowImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsLineVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmDispSlipsLineVORowImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmUpdSlipsVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03ConfirmUpdSlipsVORowImpl;
//ver11.5.10.1.6 Add End

//ver11.5.10.1.6I Add Start
import oracle.apps.xx03.ar.confirm.server.Xx03GetDefaultApproverVOImpl;
import oracle.apps.xx03.ar.confirm.server.Xx03GetDefaultApproverVORowImpl;
//ver11.5.10.1.6I Add End

//ver 11.5.10.1.6I Add Start
import oracle.apps.xx03.util.Xx03CommonUtil;
//ver 11.5.10.1.6I Add End

/**
 *
 * Xx03InvoiceInputPGのAM
 *
 * @version     11.5.10.1.6P
 */
public class Xx03ArInvoiceInputAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public Xx03ArInvoiceInputAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("oracle.apps.xx03.ar.input.server", "Xx03ArInvoiceInputAMLocal");
  }

  /**
   * 請求依頼伝票の作成
   * @param slipType 伝票種別
   * @return なし
   */
  public void createReceivableSlips(String slipType)
  {
    // 初期処理
    String methodName = "createReceivableSlips";
    startProcedure(getClass().getName(), methodName);

    // ビュー・オブジェクトの取得    
    OAViewObject vo = (OAViewObject)getXx03ReceivableSlipsVO1();
    
    if (!vo.isPreparedForExecution())
    {
      int maxFetchSize = vo.getMaxFetchSize();
      vo.setMaxFetchSize(0);
      vo.executeQuery();
      vo.setMaxFetchSize(maxFetchSize);
    }
    
    Row row = vo.createRow();
    row.setAttribute("SlipType", slipType);
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);

    // 終了処理
    endProcedure(getClass().getName(), methodName);    
  } // createReceivableSlips()

  /**
   * 請求依頼伝票明細の作成
   * @param lineCount 作成行数
   * @return なし
   */
  public void createReceivableSlipLines(Number lineCount)
  {
    // 初期化処理
    String methodName = "createReceivableSlipLines";
    startProcedure(getClass().getName(), methodName);
    
    // 明細行作成
    createReceivableDetailLines(lineCount.intValue(), false);

    // 終了処理
    endProcedure(getClass().getName(), methodName);    
   } // createReceivableSlipLines()

  /**
   * 明細行作成
   * @param displayLineCount 表示行数
   * @param isForce 明細行強制作成
   * @return なし
   */
  public void createReceivableDetailLines(int displayLineCount, boolean isForce)
  {
    // 初期化処理
    String methodName = "createReceivableDetailLines";
    startProcedure(getClass().getName(), methodName);
    
    // パラメータ・チェック
    if (displayLineCount <= 0)
    {
      // エラー・メッセージ
      MessageToken[] tokens = {new MessageToken("PARAMETER_NAME", "displayLineCount"),
                               new MessageToken("PARAMETER_VALUE", Integer.toString(displayLineCount))};
      throw new OAException("XX03", "APP-XX03-13033", tokens);      
    }
    
    // ビュー・オブジェクトの取得
    OAViewObject vo = (OAViewObject)getXx03ReceivableSlipsLineVO1();

    //Ver11.5.10.2.6B Add Start
    RowSetIterator selectIter = null;
    selectIter = vo.createRowSetIterator("selectIter");
    try
    {
    //Ver11.5.10.2.6B Add End

    // 追加空行の計算
    int addLineCount = 0;                   // 追加空行
    int lastLineCount = 0;                  // 非空行
    //Ver11.5.10.1.6J 2006/01/16 Change Start
    //int voCount = vo.getFetchedRowCount();  // ビュー・オブジェクト・インスタンスの件数
    int voCount = vo.getRowCount();         // ビュー・オブジェクト・インスタンスの件数
    //Ver11.5.10.1.6J 2006/01/16 Change End
    // 強制作成以外
    if ((!isForce) && (voCount != 0))
    {
      lastLineCount = voCount%displayLineCount;
      addLineCount = displayLineCount-lastLineCount;
    }
    // 強制作成
    else
    {
      lastLineCount = 1;
      addLineCount = displayLineCount;
    }
        //Ver11.5.10.2.6B Del Start 無駄な処理のため削除
        //vo.first();
        //for (int i=0; i<voCount; i++)
        //{
        //  Xx03ReceivableSlipsLineVORowImpl rowA = (Xx03ReceivableSlipsLineVORowImpl)vo.getCurrentRow();
        //  vo.next();
        //} // for loop
        //Ver11.5.10.2.6B Del End

    // 追加空行の作成
    if ((voCount == 0) || (lastLineCount > 0))
    {
      // 空行を作成する最終行へ移動
      //Ver11.5.10.2.6B Chg Start
      //vo.last();
      //vo.next();
      selectIter.last();
      selectIter.next();
      //Ver11.5.10.2.6B Chg End

      // 作成
      for (int i=0; i<addLineCount; i++)
      {
        //Ver11.5.10.2.6B Chg Start
        //Row row = (Row)vo.createRow();
        Row row = (Row)selectIter.createRow();
        //Ver11.5.10.2.6B Chg End

        //Ver11.5.10.1.6M Add Start
        try
        {
        //Ver11.5.10.1.6M Add End

          // デフォルト値設定
          row.setAttribute("LineNumber", new Number(voCount+i+1));
          row.setAttribute("AutoTaxExec", Xx03ArCommonUtil.STR_NO);

          //Ver11.5.10.2.6B Chg Start
          //vo.insertRow(row);
          selectIter.insertRow(row);
          //Ver11.5.10.2.6B Chg End

        //Ver11.5.10.1.6M Add Start
        }
        catch(Exception e) 
        {
          row.remove();
          throw OAException.wrapperException(e);
        }
        //Ver11.5.10.1.6M Add End
        row.setNewRowState(Row.STATUS_INITIALIZED);

        //Ver11.5.10.2.6B Chg Start
        //vo.next();
        selectIter.next();
        //Ver11.5.10.2.6B Chg End
      }
    }

    //Ver11.5.10.2.6B Del Start
    //// 1レコード目を表示  
    ////Ver11.5.10.2.6B Chg Start
    ////vo.first();
    //selectIter.first();
    ////Ver11.5.10.2.6B Chg End
    //Ver11.5.10.2.6B Del End

    // Ver11.5.10.1.4b 2005/08/02 add Start
    // 未入力時の値チェックのため、1行目の行番号の値を上書きする。実際に値の変更はなし
    // Ver11.5.10.1.5 2005/09/06 delete start
    // 前受金と一見顧客入力に対応するため、ここでの未入力チェックをはずす
    //Xx03ReceivableSlipsLineVORowImpl rowB
    //  = (Xx03ReceivableSlipsLineVORowImpl)vo.getCurrentRow();
    //rowB.setAttribute("LineNumber",new Number(1));
    // Ver11.5.10.1.5 2005/09/06 delete End
    // Ver11.5.10.1.4b 2005/08/02 add End

    //Ver11.5.10.2.6B Add Start
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }
    finally
    {
      if (selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
    //Ver11.5.10.2.6B Add End

    // 終了処理
    endProcedure(getClass().getName(), methodName);        
  } // createReceivableDetailLines()

  /**
   * 振替伝票の検索
   * @param receivableId 索引番号
   * @param executeQuery 
   * @return なし
   */
  public void initReceivableSlips(Number receivableId, Boolean executeQuery)
  {
    // 初期化処理
    String methodName = "initReceivableSlips";
    startProcedure(getClass().getName(), methodName);

    // ビュー・オブジェクトの取得
    Xx03ReceivableSlipsVOImpl vo = getXx03ReceivableSlipsVO1();
    vo.initQuery(receivableId, executeQuery);

    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // end initReceivableSlips()

  /**
   * 入力金額算出
   * @param なし
   * @return なし
   */
  public void calculateInput()
  {
    // 初期化処理
    String methodName = "calculateInput";
    startProcedure(getClass().getName(), methodName);
    
    Number enteredAmount = new Number(0); // 入力金額
    Number unitPrice = new Number(0);     // 単価
    Number quantity = new Number(0);      // 数量

    //Ver11.5.10.1.4C 2005/08/05 Add Start
    String invoiceCurrencyCode = null;        // 現在の通貨
    Number selectedPrecision = new Number(0); // 現在の通貨の精度
//ver 11.5.10.2.10D Del Start
//    int roundPrecision = 0;                   // 端数処理用変数
//ver 11.5.10.2.10D Del End
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;
    //Ver11.5.10.1.4C 2005/08/05 Add End

    RowSetIterator selectLineIter = null;
    int fetchedLineRowCount;
    
    try
    {
      // ビュー・オブジェクトの取得
      //Ver11.5.10.1.4C 2005/08/05 Add Start
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
       
        if (headerRow != null){
          // 通貨の取得
          invoiceCurrencyCode = headerRow.getInvoiceCurrencyCode();
        }
      }  // fetchedHeaderRowCount > 0

      //Ver11.5.10.1.6K 2006/01/19 Add Start
      // 通貨が取得できなかった時はエラーメッセージ表示
      if (invoiceCurrencyCode == null)
      {
        // 通貨未入力エラー・メッセージ
        throw new OAException("XX03",
                              "APP-XX03-13017",
                              null,
                              OAException.ERROR,
                              null);
      }
      //Ver11.5.10.1.6K 2006/01/19 Add End
      //Ver11.5.10.1.4C 2005/08/05 Add End

      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");


      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // *********************************************************************
            // * 単価、数量より入力金額算出
            // *********************************************************************
            // 単価
            unitPrice = lineRow.getSlipLineUnitPrice();
            // 数量
            quantity = lineRow.getSlipLineQuantity();

            //Ver11.5.10.1.4C 2005/08/05 Add Start
            // 通貨の精度取得
            selectedPrecision = getSelectedPrecision(invoiceCurrencyCode);
            //ver 11.5.10.2.10D Del Start
            //roundPrecision = selectedPrecision.intValue();
            //ver 11.5.10.2.10D Del End
            //Ver11.5.10.1.4C 2005/08/05 Add End
            
            //Ver11.5.10.1.4C 2005/08/05 Modify Start
            if ((unitPrice != null) && (quantity != null))
            {
              // 入力金額算出、Rowにセット
              enteredAmount = unitPrice.multiply(quantity);
              //ver 11.5.10.2.10B Del Start
              //enteredAmount = round(enteredAmount,roundPrecision);
              //ver 11.5.10.2.10B Del End
              //ver 11.5.10.2.10C Add Start
              //ver 11.5.10.2.10D Chg Start
              //enteredAmount = round(enteredAmount,roundPrecision);
              enteredAmount = round(enteredAmount,selectedPrecision);
              //ver 11.5.10.2.10D Chg End
              //ver 11.5.10.2.10C Add End
              lineRow.setSlipLineEnteredAmount(enteredAmount);
            }
            //Ver11.5.10.1.4C 2005/08/05 Modify End
          }
        } // for
      } // fetchedLineRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      //Ver11.5.10.1.4C 2005/08/05 Add Start
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      //Ver11.5.10.1.4C 2005/08/05 Add End
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // calculateInput()

  /**
   * 消費税の再計算
   * @param なし
   * @return なし
   */
  //Ver11.5.10.1.6K 2006/01/19 Change Start
  //public void calculateTax()
  public Vector calculateTax()
  //Ver11.5.10.1.6K 2006/01/19 Change End
  {
    // 初期化処理
    String methodName = "calculateTax()";
    startProcedure(getClass().getName(), methodName);

    //Ver11.5.10.1.6K 2006/01/19 Change Start
    //resetTaxAmount();
    Vector retVec = null;
    retVec = resetTaxAmount();
    //Ver11.5.10.1.6K 2006/01/19 Change End

    // 終了処理
    endProcedure(getClass().getName(), methodName);

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    return retVec;
    //Ver11.5.10.1.6K 2006/01/19 Add End
  } // calculateTax()

  /**
   * 消費税の再計算
   * @param なし
   * @return なし
   */
  //Ver11.5.10.1.6K 2006/01/19 Change Start
  //private void resetTaxAmount()
  private Vector resetTaxAmount()
  //Ver11.5.10.1.6K 2006/01/19 Change End
  {
    // 初期化処理
    String methodName = "resetTaxAmount";
    startProcedure(getClass().getName(), methodName);

    // 
    Number enteredAmount = new Number(0);     // 入力金額
    Number enteredItemAmount = new Number(0); // 本体税額
    Number enteredTaxAmount = new Number(0);  // 消費税額
    String taxCode = null;                    // 税区分
    Number taxRate = new Number(0);           // 税率
    String taxFlag = null;                    // 内税フラグ
    String autoTaxCalcFlag = null;            // 消費税計算レベル
    String taxRoundingRule = null;            // 消費税端数処理
    // ver1.3 add start ---------------------------------------------------------
    String invoiceCurrencyCode = null;        // 現在の通貨
    Number selectedPrecision = new Number(0); // 現在の通貨の精度
//ver 11.5.10.2.10D Del Start
//    int roundPrecision = 0;                   // 端数処理用変数
//    double roundNumber = 1;                   // 端数処理用変数
//ver 11.5.10.2.10D Del End
    // ver1.3 add end -----------------------------------------------------------
    boolean isExistExcludingTax = false;      // 外税明細存在チェック

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    Vector retVec = new Vector();
    //Ver11.5.10.1.6K 2006/01/19 Add End

    Number coordinateValue = new Number(0);   // 消費税調整額
    int coordinateId = 0;                     // 消費税調整対象

    // 自動計算がヘッダ単位の場合に、外税の金額を保存する
    Number enteredAmountExTax = new Number(0);
    Number enteredTaxAmountExTax = new Number(0);
    // 自動計算がヘッダ単位の場合に、端数処理済の外税の金額を保存する
    Number autoEnteredAmountExTax = new Number(0);
    Number autoEnteredTaxAmountExTax = new Number(0);

    RowSetIterator selectHeaderIter = null;    
    RowSetIterator selectLineIter = null;
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    // Ver11.5.10.1.3 add START
    //自動計算がヘッダ単位の場合に必要な変数
    Number headerAmount = new Number(0);      // 明細の金額合計
    Number headerTaxAmount = new Number(0);   // 合計金額に対する消費税額
    // 税額計算で利用するハッシュテーブル
    Hashtable headerAmountTable = new Hashtable();
    Hashtable headerTaxAmountTable = new Hashtable();
    // ハッシュテーブルのキー
    String tableKey = null;
    // Ver11.5.10.1.3 add END

    //Ver11.5.10.1.6E 2005/12/26 Add Start
    Date headInvDate = null;
    //Ver11.5.10.1.6E 2005/12/26 Add End

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    // 税区分Null存在チェックフラグ
    String taxNullFlag = null;
    //Ver11.5.10.1.6K 2006/01/19 Add End

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        Hashtable returnHashtable = null;

        if (headerRow != null){
          // ver1.3 add start ---------------------------------------------------------
          // 通貨の取得
          invoiceCurrencyCode = headerRow.getInvoiceCurrencyCode();
          // ver1.3 add end -----------------------------------------------------------
          // 消費税計算レベル、消費税端数処理の設定
          // 「上書の許可」オプション取得
          String strTaxOverride = getTaxOverride();
          if (strTaxOverride.equals(Xx03ArCommonUtil.STR_YES))
          {
            // 上書の許可が'Y'の場合は顧客事業所、顧客の値判定
            Number customerId = headerRow.getCustomerId();
            Number customerOfficeId = headerRow.getCustomerOfficeId();
            // 顧客事業所の消費税計算レベル、消費税端数処理取得
            returnHashtable = getCustomerTaxOption(customerId, customerOfficeId);
            //Ver11.5.10.1.5B 2005/09/27 Change Start
            // 消費税計算レベル、消費税端数処理のそれぞれがNullだったら
            // 次の優先順位のマスタを参照する
            if (returnHashtable != null)
            {
              // 戻り値が正常に取得されている場合、戻り値の値を使用
              // 消費税計算レベル
              if((returnHashtable.get("taxCalcFlag") != null)
                && (!returnHashtable.get("taxCalcFlag").equals("")))
              {
                autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
              }
              // 消費税端数処理
              if((returnHashtable.get("taxRoundingRule") != null)
                && (!returnHashtable.get("taxRoundingRule").equals("")))
              {
                taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
              }
            }
            //if ((returnHashtable != null)
            //    && (returnHashtable.get("taxCalcFlag") != null)
            //    && (!returnHashtable.get("taxCalcFlag").equals(""))
            //    && (returnHashtable.get("taxRoundingRule") != null)
            //    && (!returnHashtable.get("taxRoundingRule").equals("")))
            //{
            //  // 戻り値が正常に取得されている場合、戻り値の値を使用
            //  autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
            //  taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
            //}
            //Ver11.5.10.1.5B 2005/09/27 Change End
          }

          // 顧客事業所、顧客に値が設定されていない場合、上書の許可が'N'の場合は
          // システムオプションの値取得
          if ((autoTaxCalcFlag == null) || (autoTaxCalcFlag.equals(""))
              || (taxRoundingRule == null) || (taxRoundingRule.equals("")))
          {
            // システムオプションの消費税計算レベル、消費税端数処理取得
            returnHashtable = getSystemTaxOption();
            if ((returnHashtable != null)
                && (returnHashtable.get("taxCalcFlag") != null)
                && (!returnHashtable.get("taxCalcFlag").equals(""))
                && (returnHashtable.get("taxRoundingRule") != null)
                && (!returnHashtable.get("taxRoundingRule").equals("")))
            {
              //Ver11.5.10.1.5B 2005/09/27 Change Start
              // 消費税計算レベルに値が設定されていなければシステムオプションの値を設定する
              if((autoTaxCalcFlag == null) || (autoTaxCalcFlag.equals("")))
              {
                  autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
              }
              // 消費税端数処理に値が設定されていなければシステムオプションの値を設定する
              if((taxRoundingRule == null) || (taxRoundingRule.equals("")))
              {
                  taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
              }
              // // 戻り値が正常に取得されている場合、戻り値の値を使用
              // autoTaxCalcFlag = (String)returnHashtable.get("taxCalcFlag");
              // taxRoundingRule = (String)returnHashtable.get("taxRoundingRule");
              //Ver11.5.10.1.5B 2005/09/27 Change End
            }
          }

          //Ver11.5.10.1.6E 2005/12/26 Add Start
          headInvDate = headerRow.getInvoiceDate();
          //Ver11.5.10.1.6E 2005/12/26 Add End

        } // headerRow       
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount

      //Ver11.5.10.1.6K 2006/01/19 Add Start
      // 通貨が取得できなかった時はエラーメッセージ表示
      if (invoiceCurrencyCode == null)
      {
        // 通貨未入力エラー・メッセージ
        throw new OAException("XX03",
                              "APP-XX03-13017",
                              null,
                              OAException.ERROR,
                              null);
      }
      //Ver11.5.10.1.6K 2006/01/19 Add End

      //ver 11.5.10.2.10E Add Start
      // 請求書日付が取得できなかった時はエラーメッセージ表示
      if (headInvDate == null)
      {
        // 請求書日付未入力エラー・メッセージ
        throw new OAException("XX03",
                              "APP-XX03-13013",
                              null,
                              OAException.ERROR,
                              null);
      }
      //ver 11.5.10.2.10E Add End

      //Ver11.5.10.1.6K 2006/01/19 Add Start
      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        //ver 11.5.10.2.10E Add Start
        //エラー発生時用の変数宣言
        OAException msg;
        MessageToken slipNumTok = new MessageToken("SLIP_NUM","");
        MessageToken countTok;
        //ver 11.5.10.2.10E Add End

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          //ver 11.5.10.2.10E Add Start
          //エラー発生時用の行数を用意
          countTok = new MessageToken("TOK_COUNT",lineRow.getLineNumber().toString());
          //ver 11.5.10.2.10E Add End

          if (lineRow != null)
          {
            if  ((lineRow.getSlipLineUnitPrice() != null)
                && (lineRow.getSlipLineQuantity() != null)
                && (lineRow.getTaxCode() == null))
            {
              //ver 11.5.10.2.10E Chg Start
              //MessageToken slipNumTok = new MessageToken("SLIP_NUM","");
              //MessageToken countTok = new MessageToken("TOK_COUNT",
              //                         lineRow.getLineNumber().toString());
              //OAException msg = new OAException("XX03",
              //                      "APP-XX03-14151",
              //                      new MessageToken[]{slipNumTok ,countTok},
              //                      OAException.ERROR,
              //                      null);
              msg = new OAException("XX03",
                                    "APP-XX03-14151",
                                    new MessageToken[]{slipNumTok ,countTok},
                                    OAException.ERROR,
                                    null);
              //ver 11.5.10.2.10E Chg End
              retVec.addElement(msg);

              taxNullFlag = "1";
            }

            //ver 11.5.10.2.10E Add Start
            // 税金コードチェック
            if (    (headerRow.getInvoiceDate() != null) && (!headerRow.getInvoiceDate().equals(""))
                 && (lineRow.getTaxName()       != null) && (!lineRow.getTaxName().equals("")      )
                 && (lineRow.getTaxCode()       != null) && (!lineRow.getTaxCode().equals("")      ) )
            {
              ArrayList slipLineTaxInfo = getSlipLineTaxName(lineRow.getTaxName(), lineRow.getTaxCode(), headerRow.getInvoiceDate());
              if (slipLineTaxInfo.isEmpty())
              {
                msg = new OAException( "XX03" ,"APP-XX03-14151"
                                      ,new MessageToken[]{slipNumTok ,countTok} ,OAException.ERROR ,null);
                retVec.addElement(msg);
                taxNullFlag = "1";
              }
              else
              {
                Number getTaxId = (Number)slipLineTaxInfo.get(1);
                String getIncTaxFlag = (String)slipLineTaxInfo.get(2);
                if (!lineRow.getTaxId().equals(getTaxId))
                {
                  msg = new OAException( "XX03" ,"APP-XX03-14151"
                                        ,new MessageToken[]{slipNumTok ,countTok} ,OAException.ERROR ,null);
                  retVec.addElement(msg);
                  taxNullFlag = "1";
                }
                else if (!getIncTaxFlag.equals(lineRow.getAmountIncludesTaxFlag()))
                {
                  msg = new OAException( "XX03" ,"APP-XX03-13070"
                                        ,new MessageToken[]{slipNumTok ,countTok} ,OAException.ERROR ,null);
                  retVec.addElement(msg);
                  taxNullFlag = "1";
                }
              }
            }
            //ver 11.5.10.2.10E Add End

          } // lineRow != null
        } // for loop
      }

    //税区分Nullがある時は計算は行わない
    if (taxNullFlag == null)
    {
    //Ver11.5.10.1.6K 2006/01/19 Add End

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            if ((lineRow.getSlipLineUnitPrice() != null)
                && (lineRow.getSlipLineQuantity() != null)
                && (lineRow.getTaxCode() != null))
            {
              // *********************************************************************
              // * 消費税の算出
              // *********************************************************************
              // 入力金額取得
              // 検証処理はEOにて実行
              enteredAmount = lineRow.getSlipLineEnteredAmount();

              // 税額取得
              enteredTaxAmount = lineRow.getEnteredTaxAmount();
              
              // ver1.3 add start ---------------------------------------------------------
              // 通貨の精度取得
              selectedPrecision = getSelectedPrecision(invoiceCurrencyCode);
//ver 11.5.10.2.10D Del Start
//              roundPrecision = selectedPrecision.intValue();
//              // Ver1.4 change start ------------------------------------------------------
//              if(roundPrecision>0)
//              {
//                BigDecimal scale = new BigDecimal("1");
//                scale = scale.movePointRight(roundPrecision);
//                roundNumber = scale.doubleValue();
//              }              
//ver 11.5.10.2.10D Del End
//              if(roundPrecision>0)
//              {
//                BigDecimal scale = new BigDecimal("10");
//                scale.movePointRight(roundPrecision);
//                roundNumber = scale.doubleValue();
//              }
              // Ver1.4 change end --------------------------------------------------------
              // ver1.3 add end -----------------------------------------------------------

              // 税区分取得
              // 検証処理はEOにて実行
              taxCode = lineRow.getTaxCode();

              // 内税フラグ
              // ver 1.2 Change Start 内税フラグを税区分から取得するよう変更
              //              taxFlag = lineRow.getAmountIncludesTaxFlag();
              //Ver11.5.10.1.6E 2005/12/26 Change Start
//              taxFlag = getIncludesTaxFlag(taxCode);
              if(headInvDate != null)
              {
                taxFlag = getIncludesTaxFlag(taxCode, headInvDate);
              }
              //Ver11.5.10.1.6E 2005/12/26 Change End
              // ver 1.2 Change End

              //Ver11.5.10.1.3 modify START
              //if (enteredAmount != null
              // 入力金額がNULLでない、かつ税計算レベルが「明細」の場合
              if (enteredAmount != null && Xx03ArCommonUtil.AUTO_TAX_CALC_ON_LINE.compareTo(autoTaxCalcFlag) == 0)
              //Ver11.5.10.1.3 modify END
              {
                //Ver11.5.10.1.6E 2005/12/26 Change Start
//                // 税率取得
//                taxRate = getTaxRate(lineRow.getTaxCode());
                if(headInvDate != null)
                {
//                taxRate = getTaxRate(lineRow.getTaxCode());
                  taxRate = getTaxRate(lineRow.getTaxCode(), headInvDate);
                }
                //Ver11.5.10.1.6E 2005/12/26 Change End
                // 内税の場合
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  enteredTaxAmount = enteredAmount.multiply(taxRate).divide(taxRate.add(100));
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);
                  //ver 11.5.10.2.10B Del End
                }
                // 外税の場合
                else
                {
                  enteredTaxAmount = enteredAmount.multiply(taxRate).divide(100);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = enteredAmount;
                  //ver 11.5.10.2.10B Del End

                  // 外税明細の存在チェック
                  isExistExcludingTax = true;

                  // 消費税調整対象の明細を保持
                  coordinateId = i;
                }
      // ver1.3 change start ------------------------------------------------------
                // 端数処理規則が切り下げの場合
                if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
                {
                  //Ver11.5.10.1.4 2005/07/25 Modify Start
                  // 消費税計算ロジックの変更
                  //enteredTaxAmount = (Number)enteredTaxAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                  //ver 11.5.10.2.10D Chg Start
                  //enteredTaxAmount = roundDown(enteredTaxAmount,roundNumber);
                  enteredTaxAmount = roundDown(enteredTaxAmount,selectedPrecision);
                  //ver 11.5.10.2.10D Chg End
                  // 内税の場合は、本体の切り上げが必要
                  // 外税の場合は、本体の切り上げは不要だが、統一して行う
                  //enteredItemAmount = (Number)enteredItemAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = roundUp(enteredItemAmount,roundNumber);
                  //ver 11.5.10.2.10B Del End
                  //Ver11.5.10.1.4 2005/07/25 Modify End
                }
                // 端数処理規則が切り上げの場合
                else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
                {
                  //Ver11.5.10.1.4 2005/07/25 Modify Start
                  // 消費税計算ロジックの変更
                  //enteredTaxAmount = (Number)enteredTaxAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
                  //ver 11.5.10.2.10D Chg Start
                  //enteredTaxAmount = roundUp(enteredTaxAmount,roundNumber);
                  enteredTaxAmount = roundUp(enteredTaxAmount,selectedPrecision);
                  //ver 11.5.10.2.10D Chg End
                  // 内税の場合は、本体の切り下げが必要
                  // 外税の場合は、本体の切り下げは不要だが、統一して行う
                  //enteredItemAmount = (Number)enteredItemAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = roundDown(enteredItemAmount,roundNumber);
                  //ver 11.5.10.2.10B Del End
                  //Ver11.5.10.1.4 2005/07/25 Modify End
                }
                // 端数処理規則が四捨五入の場合
                else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
                {
                  //Ver11.5.10.1.4 2005/07/25 Modify Start
                  // 消費税計算ロジックの変更
                  //enteredTaxAmount = (Number)enteredTaxAmount.round(roundPrecision);
                  //ver 11.5.10.2.10D Chg Start
                  //enteredTaxAmount = round(enteredTaxAmount,roundPrecision);
                  enteredTaxAmount = round(enteredTaxAmount,selectedPrecision);
                  //ver 11.5.10.2.10D Chg End
                  // 内税の場合は、本体の四捨五入が必要
                  // 外税の場合は、本体の四捨五入は不要だが、統一して行う
                  //enteredItemAmount = (Number)enteredItemAmount.round(roundPrecision);
                  //ver 11.5.10.2.10B Del Start
                  //enteredItemAmount = round(enteredItemAmount,roundPrecision);
                  //ver 11.5.10.2.10B Del End
                  //Ver11.5.10.1.4 2005/07/25 Modify End
                }

                //Ver11.5.10.1.3 modify START
                //lineRow.setEnteredItemAmount(enteredItemAmount);            
                //lineRow.setEnteredTaxAmount(enteredTaxAmount);
                //Ver11.5.10.1.3 modify END

                //ver 11.5.10.2.10B Add Start
                // 内税の場合
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);
                }
                // 外税の場合
                else
                {
                  enteredItemAmount = enteredAmount;
                }
                //ver 11.5.10.2.10B Add End

              } // enteredAmount != null、税計算レベルが「明細」
              //Ver11.5.10.1.3 modify START
              // 入力金額がNULLでない、かつ税計算レベルが「ヘッダー」の場合
              else if (enteredAmount != null && Xx03ArCommonUtil.AUTO_TAX_CALC_ON_HEADER.compareTo(autoTaxCalcFlag) == 0)
              {
                //Ver11.5.10.1.6E 2005/12/26 Change Start
//                // 税率取得
//                taxRate = getTaxRate(lineRow.getTaxCode());
                if(headInvDate != null)
                {
//                taxRate = getTaxRate(lineRow.getTaxCode());
                  taxRate = getTaxRate(lineRow.getTaxCode(), headInvDate);
                }
                //Ver11.5.10.1.6E 2005/12/26 Change End
                // 内税の場合
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  //キーの定義
                  tableKey = "i" + taxRate.toString();
                  //ハッシュテーブルheaderAmountTableにキーで定義した値が存在しない場合
                  if (headerAmountTable.get(tableKey) == null)
                  {
                    headerAmount = enteredAmount;
                  }
                  else //存在する場合
                  {
                    headerAmount = (Number)enteredAmount.add((Number)headerAmountTable.get(tableKey));
                  }
                  //合計金額の消費税を計算する
                  headerTaxAmount = headerAmount.multiply(taxRate).divide(taxRate.add(100));
                  // 消費税の端数処理を行なう
                  // 端数処理規則が切り下げの場合
                  if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //消費税計算ロジックの変更
                    //headerTaxAmount = (Number)headerTaxAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundDown(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundDown(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // 端数処理規則が切り上げの場合
                  else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //消費税計算ロジックの変更
                    //headerTaxAmount = (Number)headerTaxAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundUp(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundUp(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // 端数処理規則が四捨五入の場合
                  else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //消費税計算ロジックの変更
                    //headerTaxAmount = (Number)headerTaxAmount.round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = round(headerTaxAmount,roundPrecision);
                    headerTaxAmount = round(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // ハッシュテーブルに合計金額を保存
                  headerAmountTable.put(tableKey,headerAmount);

                  // ハッシュテーブルheaderTaxAmountTableに上で定義したキーを持つ値が存在しない場合
                  if (headerTaxAmountTable.get(tableKey) == null)
                  {
                    // 消費税額を確定する
                    enteredTaxAmount = headerTaxAmount;
                    // 現在の消費税額を保存
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  else
                  {
                    // 合計の消費税から、前に保存した消費税額を引く
                    enteredTaxAmount = (Number)headerTaxAmount.subtract((Number)headerTaxAmountTable.get(tableKey));
                    // 現在の合計消費税額を保存
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  // 明細の税抜き金額を算出
                  enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);
                } //税計算レベル「ヘッダー」、内税
                // 外税の場合
                else
                {
                  tableKey = "o" + taxRate.toString();
                  //ハッシュテーブルheaderAmountTableにキーで定義した値が存在しない場合
                  if (headerAmountTable.get(tableKey) == null)
                  {
                    headerAmount = enteredAmount;
                  }
                  else //存在する場合
                  {
                    headerAmount = (Number)enteredAmount.add((Number)headerAmountTable.get(tableKey));
                  }
                  //合計金額の消費税を計算する
                  headerTaxAmount = headerAmount.multiply(taxRate).divide(100);
                  // 消費税の端数処理を行なう
                  // 端数処理規則が切り下げの場合
                  if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //消費税計算ロジックの変更
                    //headerTaxAmount = (Number)headerTaxAmount.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundDown(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundDown(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // 端数処理規則が切り上げの場合
                  else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //消費税計算ロジックの変更
                    //headerTaxAmount = (Number)headerTaxAmount.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = roundUp(headerTaxAmount,roundNumber);
                    headerTaxAmount = roundUp(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // 端数処理規則が四捨五入の場合
                  else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
                  {
                    //Ver11.5.10.1.4 2005/07/25 Modify Start
                    //消費税計算ロジックの変更
                    //headerTaxAmount = (Number)headerTaxAmount.round(roundPrecision);
                    //ver 11.5.10.2.10D Chg Start
                    //headerTaxAmount = round(headerTaxAmount,roundPrecision);
                    headerTaxAmount = round(headerTaxAmount,selectedPrecision);
                    //ver 11.5.10.2.10D Chg End
                    //Ver11.5.10.1.4 2005/07/25 Modify End
                  }
                  // ハッシュテーブルに合計金額を保存
                  headerAmountTable.put(tableKey,headerAmount);

                  // ハッシュテーブルheaderTaxAmountTableに上で定義したキーを持つ値が存在しない場合
                  if (headerTaxAmountTable.get(tableKey) == null)
                  {
                    // 消費税額を確定する
                    enteredTaxAmount = headerTaxAmount;
                    // 現在の消費税額を保存
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  else
                  {
                    // 合計の消費税から、前に保存した消費税額を引く
                    enteredTaxAmount = (Number)headerTaxAmount.subtract((Number)headerTaxAmountTable.get(tableKey));
                    // 現在の合計消費税額を保存
                    headerTaxAmountTable.put(tableKey,headerTaxAmount);
                  }
                  // 明細の税抜き金額
                  enteredItemAmount = enteredAmount;
                  
                } //税計算レベル「ヘッダー」、外税
              } // 入力金額がNULLでない、かつ税計算レベル「ヘッダー」
              //確定した消費税、税抜き金額をlineRowに戻す
              lineRow.setEnteredItemAmount(enteredItemAmount);
              lineRow.setEnteredTaxAmount(enteredTaxAmount);
              //Ver11.5.10.1.3 modify END
            } // 単価、数量、税区分あり
          } // lineRow != null
        } // for loop

        //Ver11.5.10.1.3 DELETE START
        //// *************************************************************************
        //// * 消費税の調整
        //// *************************************************************************
        //// 外税の明細が存在する、且つ自動計算の計算レベルがヘッダーの場合
        //if ((isExistExcludingTax) && (Xx03ArCommonUtil.AUTO_TAX_CALC_ON_HEADER.compareTo(autoTaxCalcFlag) == 0))
        //{
        //  // 外税の明細の入力金額(本体金額)を足しこんだ額に対して、消費税計算、端数処理を行う
        //  autoEnteredTaxAmountExTax = enteredAmountExTax.multiply(taxRate).divide(100);

        //  // 端数処理規則が切り下げの場合
        //  if (Xx03ArCommonUtil.ROUND_DOWN.compareTo(taxRoundingRule) == 0)
        //  {
        //     autoEnteredTaxAmountExTax = (Number)autoEnteredTaxAmountExTax.subtract(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);
        //  }
        //  // 端数処理規則が切り上げの場合
        //  else if (Xx03ArCommonUtil.ROUND_UP.compareTo(taxRoundingRule) == 0)
        //  {
        //    autoEnteredTaxAmountExTax = (Number)autoEnteredTaxAmountExTax.add(Xx03ArCommonUtil.ROUND_NUMBER/roundNumber).round(roundPrecision);                
        //  }
        //  // 四捨五入(消費税)なので、四捨五入(消費税) : round
        //  else if (Xx03ArCommonUtil.ROUND.compareTo(taxRoundingRule) == 0)
        // {
        //    autoEnteredTaxAmountExTax = (Number)autoEnteredTaxAmountExTax.round(roundPrecision);
        //  }

        //  // 仕訳レベルの消費税額と明細レベルの消費税額を比較
        //  coordinateValue = autoEnteredTaxAmountExTax.subtract(enteredTaxAmountExTax);

        //  if (coordinateValue.compareTo(0) != 0)
        //  {
        //    lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(coordinateId);
        //    lineRow.setEnteredTaxAmount(lineRow.getEnteredTaxAmount().add(coordinateValue));
        //  }
        //}
        //Ver11.5.10.1.3 DELETE END
      // ver1.3 change end --------------------------------------------------------
      } // fetchedLineRowCount > 0

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    }
    //Ver11.5.10.1.6K 2006/01/19 Add End

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator(); 
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }

    //Ver11.5.10.1.6K 2006/01/19 Add Start
    return retVec;
    //Ver11.5.10.1.6K 2006/01/19 Add End

  } // resetTaxAmount()

  /**
   * 税率の取得
   * @param taxCode 税コード
   * @return Number 税率
   */
  //Ver11.5.10.1.6E 2005/12/26 Change Start
//  private Number getTaxRate(String taxCode)
  private Number getTaxRate(String taxCode,Date GlDate)
  //Ver11.5.10.1.6E 2005/12/26 Change End
  {
    Number retNum = null;
    
    // ビュー・オブジェクトの取得
    Xx03TaxCodesLovVOImpl vo = getXx03TaxCodesLovVO1();

    //Ver11.5.10.1.6E 2005/12/26 Change Start
//    vo.initQuery(taxCode);
    vo.initQuery(taxCode, GlDate);
    //Ver11.5.10.1.6E 2005/12/26 Change End

    vo.first();

    Xx03TaxCodesLovVORowImpl row = (Xx03TaxCodesLovVORowImpl)vo.getCurrentRow();

    if (row != null)
    {
      retNum = row.getTaxRate();
    }

    if (retNum == null)
    {
      throw new OAException("XX03",
                            "APP-XX03-08035",
                            null,
                            OAException.ERROR,
                            null);
    }
    
    return retNum;
  }

  /**
   * 変更判定(全体)
   * @param なし
   * @return 変更があったかどうか
   */
  public boolean isDirty()
  {
    // 初期化処理
    String methodName = "isDirty";
    startProcedure(getClass().getName(), methodName);
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return getTransaction().isDirty();
  }

  /**
   * 金額の再計算
   * @param なし
   * @return なし
   */
  public void recalculate()
  {
    String methodName = "recalculate";
    startProcedure(getClass().getName(), methodName); 

    // 入力金額算出
    calculateInput();

    // 入力金額、本体金額、消費税額、換算済金額の算出
    int coordinateId = resetAmount();

    // 合計金額の算出
    resetTotalAmount();

    // 換算済金額の調整
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    RowSetIterator selectHeaderIter = null;    
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    try
    {
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);
        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          // Validation
          headerRow.validate();
        } // headerRow
      } // fetchedHeaderRocCount
      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  }

  /**
   * 手動でのValidationチェック
   * @param なし
   * @return 
   */
  //ver11.5.10.1.6 Chg Start
//  public void checkSelfValidation()
  public Vector checkSelfValidation()
  //ver11.5.10.1.6 Chg End
  {
    // 初期化処理
    String methodName = "checkSelfValidation";
    startProcedure(getClass().getName(), methodName);

    //ver11.5.10.1.6 Add Start
    Vector msg = new Vector();
    //ver11.5.10.1.6 Add End

    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;

    //ver11.5.10.1.6 Chg Start
//    int fetchedHeaderRowCount;
//    int fetchedLineRowCount;
    int getHeaderRowCount;
    int getLineRowCount;
    //ver11.5.10.1.6 Chg End

    //ver 11.5.10.1.6I Add Start
    RowSetIterator selectSlipIter = null;    
    int getSlipRowCount;
    //ver 11.5.10.1.6I Add End

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsVORowImpl headerRow = null;

      //ver11.5.10.1.6 Chg Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      getHeaderRowCount = headerVo.getRowCount();
      //ver11.5.10.1.6 Chg End

      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;

      //ver11.5.10.1.6 Chg Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      getLineRowCount = lineVo.getRowCount();
      //ver11.5.10.1.6 Chg End

      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      //ver 11.5.10.1.6I Add Start
      OAViewObject slipVo  = getXx03SlipTypesLovVO1();
      Xx03SlipTypesLovVORowImpl slipRow  = null;
      getSlipRowCount  = slipVo.getRowCount();
      selectSlipIter  = slipVo.createRowSetIterator("selectSlipIter");
      //ver 11.5.10.1.6I Add End

      //ver 11.5.10.1.6I Chg Start
      ////ver11.5.10.1.6 Chg Start
      ////if (fetchedHeaderRowCount > 0)
      //if (getHeaderRowCount > 0)
      ////ver11.5.10.1.6 Chg End
      if ((getHeaderRowCount > 0) && (getSlipRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        selectHeaderIter.setRangeStart(0);
        //ver11.5.10.1.6 Chg Start
        //selectHeaderIter.setRangeSize(fetchedHeaderRowCount);
        selectHeaderIter.setRangeSize(getHeaderRowCount);
        //ver11.5.10.1.6 Chg End

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        //ver 11.5.10.1.6I Add Start
        selectSlipIter.setRangeStart(0);
        selectSlipIter.setRangeSize(getSlipRowCount);
        slipRow = (Xx03SlipTypesLovVORowImpl)selectSlipIter.first();
        //ver 11.5.10.1.6I Add End

        //ver 11.5.10.1.6I Chg Start
        //if (headerRow != null){
        if ((headerRow != null) && (slipRow != null))
        {
        //ver 11.5.10.1.6I Chg End
          // Validation
          //ver11.5.10.1.6 Add Start
          //headerRow.validate();
          // チェック対象
          //ver 11.5.10.1.6I Chg Start
          //msg = (Vector)validateHeader( msg
          //                             ,methodName
          //                             ,headerRow.getReceivableNum()       // 伝票番号
          //                             ,headerRow.getSlipType()            // 伝票種別コード
          //                             ,headerRow.getTransTypeId()         // 取引ＩＤ
          //                             ,headerRow.getCustomerId()          // 顧客ＩＤ
          //                             ,headerRow.getCustomerOfficeId()    // 顧客事業所ＩＤ
          //                             ,headerRow.getReceiptMethodId()     // 支払方法ＩＤ
          //                             ,headerRow.getTermsId()             // 支払条件ＩＤ
          //                             ,headerRow.getInvoiceCurrencyCode() // 通貨コード
          //                             ,headerRow.getInvoiceDate()         // 請求書日付
          //                             ,headerRow.getOrigInvoiceNum()      // 修正元伝票番号
          //                             );
          msg = (Vector)validateHeader( msg
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // 伝票番号
                                       ,headerRow.getSlipType()            // 伝票種別コード
                                       ,headerRow.getTransTypeId()         // 取引ＩＤ
                                       ,headerRow.getCustomerId()          // 顧客ＩＤ
                                       ,headerRow.getCustomerOfficeId()    // 顧客事業所ＩＤ
                                       ,headerRow.getReceiptMethodId()     // 支払方法ＩＤ
                                       ,headerRow.getTermsId()             // 支払条件ＩＤ
                                       ,headerRow.getInvoiceCurrencyCode() // 通貨コード
                                       ,headerRow.getInvoiceDate()         // 請求書日付
                                       ,headerRow.getOrigInvoiceNum()      // 修正元伝票番号
                                       ,headerRow.getWfStatus()            // ワークフローステータス
                                       ,headerRow.getApproverPersonId()    // 承認者ＩＤ
                                       ,slipRow.getAttribute14()           // 伝票種別アプリ
                                       );
          //ver 11.5.10.1.6I Chg End
          //ver11.5.10.1.6 Add End
        } // headerRow
      } // getHeaderRocCount
      //ver 11.5.10.1.6I Chg Start
      //else
      else if (!(getHeaderRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6I Add Start
      else if (!(getSlipRowCount > 0))
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03SlipTypesLovVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // updRowCount
      //ver 11.5.10.1.6I Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedLineRowCount > 0)
      if (getLineRowCount > 0)
      //ver11.5.10.1.6 Chg End
      {
        selectLineIter.setRangeStart(0);
        //ver11.5.10.1.6 Chg Start
        //selectLineIter.setRangeSize(fetchedLineRowCount);
        selectLineIter.setRangeSize(getLineRowCount);
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //for (int i=0; i<fetchedLineRowCount; i++)
        for (int i=0; i<getLineRowCount; i++)
        //ver11.5.10.1.6 Chg End
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // Validation
            //ver11.5.10.1.6 Chg Start
            //lineRow.validate();


            //Ver11.5.10.1.6E 2005/12/26 Change Start
            //msg = (Vector)validateLine( msg
            //                           ,i
            //                           ,methodName
            //                           ,headerRow.getReceivableNum()       // 伝票番号
            //                           ,headerRow.getSlipType()            // 伝票種別コード
            //                           ,headerRow.getInvoiceDate()         // 請求書日付
            //                           ,lineRow.getSlipLineType()          // 請求内容ＩＤ
            //                           ,lineRow.getSlipLineUom()           // 単位
            //                           );
            msg = (Vector)validateLine( msg
                                       ,i
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // 伝票番号
                                       //ver 11.5.10.1.6Q Del Start
                                       //,headerRow.getSlipType()            // 伝票種別コード
                                       //ver 11.5.10.1.6Q Del End
                                       ,headerRow.getInvoiceDate()         // 請求書日付
                                       //ver 11.5.10.1.6Q Del Start
                                       //,lineRow.getSlipLineType()          // 請求内容ＩＤ
                                       //ver 11.5.10.1.6Q Del End
                                       ,lineRow.getSlipLineUom()           // 単位
                                       ,lineRow.getTaxName()
                                       ,lineRow.getTaxCode()
                                       //Ver11.5.10.1.6P Add Start
                                       ,lineRow.getTaxId()
                                       //Ver11.5.10.1.6P Add End
                                       //Ver11.5.10.1.6R Add Start
                                       ,lineRow.getAmountIncludesTaxFlag()
                                       //Ver11.5.10.1.6R Add End
                                       );
            //Ver11.5.10.1.6E 2005/12/26 Change End
            //ver11.5.10.1.6 Chg End
          } // lineRow != null
        } // for loop
      } // getLineRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    //ver 11.5.10.1.6Q Add Start
    catch (OAException oaEx)
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
      if(selectSlipIter != null)
      {
        selectSlipIter.closeRowSetIterator();
      }
      throw new OAException(oaEx.getMessage());
    }
    //ver 11.5.10.1.6Q Add End
    //ver 11.5.10.1.6Q Chg Start
    //finally
    //{
    //  if(selectHeaderIter != null)
    //  {
    //    selectHeaderIter.closeRowSetIterator();
    //  }
    //  if(selectLineIter != null)
    //  {
    //    selectLineIter.closeRowSetIterator();
    //  }
    //  //ver11.5.10.1.6 Add Start
    //  return msg;
    //  //ver11.5.10.1.6 Add End
    //}
    selectHeaderIter.closeRowSetIterator();
    selectLineIter.closeRowSetIterator();
    selectSlipIter.closeRowSetIterator();
    return msg;
    //ver 11.5.10.1.6Q Chg End
  } // resetAmount()

  /**
   * 本体金額の算出、換算済金額の算出
   * @param なし
   * @return 
   */
  private int resetAmount()
  {
    // 初期化処理
    String methodName = "resetAmount";
    startProcedure(getClass().getName(), methodName);

    Number enteredAmount = new Number(0);     // 入力金額
    Number enteredTaxAmount = new Number(0);  // 消費税額
    String taxFlag = null;                    // 内税フラグ
    String taxCode = null;                    // 税区分
    Number enteredItemAmount = new Number(0); // 本体金額
    Number accountedAmount = new Number(0);   // 換算済金額
    String invoiceCurrencyCode = null;        // 通貨
    Number exchangeRate = new Number(0);      // レート
    String currencyCode = null;               // 機能通貨
    Number precision = new Number(0);         // 機能通貨の精度

    RowSetIterator selectHeaderIter = null;    
    RowSetIterator selectLineIter = null;
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    //Ver11.5.10.1.6E 2005/12/26 Add Start
    Date headInvDate = null;
    //Ver11.5.10.1.6E 2005/12/26 Add End

    try
    {
      Number maxAccountedAmount = new Number(0);                    // 調整対象の借方換算済金額
      int coordinateId = new Integer(Integer.MAX_VALUE).intValue(); // 調整対象の借方VO
    
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      // 機能通貨の取得
      currencyCode = getCurrencyCode();
      
      // 機能通貨の精度情報取得
      precision = getPrecision();

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          // 通貨取得
          // 検証処理はEOにて実行
          invoiceCurrencyCode = headerRow.getInvoiceCurrencyCode();
          if ( invoiceCurrencyCode == null )
          {
            // 通貨未入力
            // エラー・メッセージ
            MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
            throw new OAException("XX03", "APP-XX03-13017", tokens);        
          }
      
          // レート取得
          exchangeRate = headerRow.getExchangeRate();

          //Ver11.5.10.1.6E 2005/12/26 Add Start
          headInvDate = headerRow.getInvoiceDate();
          //Ver11.5.10.1.6E 2005/12/26 Add End

        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            if ((lineRow.getSlipLineUnitPrice() != null)
                && (lineRow.getSlipLineQuantity() != null)
                && (lineRow.getTaxCode() != null))
            {
              // *********************************************************************
              // * 本体金額の算出
              // *********************************************************************
              // 入力金額取得
              enteredAmount = lineRow.getSlipLineEnteredAmount();

              // 消費税金額取得
              enteredTaxAmount = lineRow.getEnteredTaxAmount();

              // 税区分取得
              taxCode = lineRow.getTaxCode();

              // 換算済金額の取得
              accountedAmount = lineRow.getAccountedAmount();

              // 内税フラグ取得
// ver 1.2 Change Start 内税フラグを税区分から取得するよう変更
//              taxFlag = lineRow.getAmountIncludesTaxFlag();

              //Ver11.5.10.1.6E 2005/12/26 Change Start
//              taxFlag = getIncludesTaxFlag(taxCode);
              if(headInvDate != null)
              {
                taxFlag = getIncludesTaxFlag(taxCode, headInvDate);
              }
              //Ver11.5.10.1.6E 2005/12/26 Change End

// ver 1.2 Change End

              if ((enteredAmount != null) && (enteredTaxAmount != null))
              {
                // 内税の場合
                if (Xx03ArCommonUtil.STR_YES.compareTo(taxFlag) == 0)
                {
                  enteredItemAmount = enteredAmount.subtract(enteredTaxAmount);    
                }
                // 外税の場合
                else
                {
                  enteredItemAmount = enteredAmount;    
                }
                lineRow.setEnteredItemAmount(enteredItemAmount);            

                // *******************************************************************
                // * 換算済金額の算出
                // *******************************************************************
                if (currencyCode.compareTo(invoiceCurrencyCode) == 0)
                {
                  // 機能通貨の場合
                  accountedAmount = enteredItemAmount.add(enteredTaxAmount);            
                }
                else{
                  // 外貨の場合
                  // 機能通貨の精度で四捨五入
                  if ( exchangeRate != null )
                  {
                    // レート入力あり
                    accountedAmount = (Number)enteredItemAmount.add(enteredTaxAmount).multiply(exchangeRate).round(precision.intValue());
                  }
                  else{
                    // レート未入力
                    // エラー・メッセージ
                    MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
                    throw new OAException("XX03", "APP-XX03-13040", tokens);        
                  }

                  // 調整対象の借方換算済金額、IDを保持
                  if (maxAccountedAmount.compareTo((Number)accountedAmount.abs()) <= 0)
                  {
                    maxAccountedAmount = accountedAmount;
                    coordinateId = i;
                  }
                }
                lineRow.setAccountedAmount(accountedAmount);
              } // enteredAmountDr != null        
            } // 単価、数量、税区分がある
          } // lineRow != null
        } // for loop
      } // fetchedLineRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);

      return coordinateId;
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // resetAmount()

  /**
   * 合計金額の算出
   * @param なし
   * @return なし
   */
  private void resetTotalAmount()
  {
    // 初期化処理
    String methodName = "resetTotalAmount";
    startProcedure(getClass().getName(), methodName);

    Number totalItemEntered = new Number(0);  // 本体合計金額
    Number totalTaxEntered = new Number(0);   // 消費税合計金額
    Number totalEntered = new Number(0);      // 合計金額(本体+消費税)
    Number totalAccounted = new Number(0);    // 換算済合計金額

    RowSetIterator selectHeaderIter = null;    
    RowSetIterator selectLineIter = null;
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (headerVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      if (lineVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if ((lineRow != null) &&
              ((lineRow.getSlipLineTypeName() != null) && 
               (!"".equals(lineRow.getSlipLineTypeName()))) &&
              (lineRow.getSlipLineUnitPrice() != null) &&
              (lineRow.getSlipLineQuantity() != null) &&
              (lineRow.getTaxCode() != null))
          {
            // *********************************************************************
            // * 合計金額の算出
            // *********************************************************************
            totalItemEntered = totalItemEntered.add(lineRow.getEnteredItemAmount());
            totalTaxEntered = totalTaxEntered.add(lineRow.getEnteredTaxAmount());
            totalEntered = totalItemEntered.add(totalTaxEntered);
            totalAccounted = totalAccounted.add(lineRow.getAccountedAmount());
          } // lineRow != null        
        } // for loop

        // 充当金額算出
        Number commitmentAmount = new Number(0);
        // 充当伝票番号が指定されている場合
        if (headerRow.getCommitmentNumber() != null)
        {
          // 本体金額＋消費税額＞＝充当残高 → 充当金額＝充当残高
          if (((totalItemEntered.add(totalTaxEntered)).compareTo(headerRow.getCommitmentAmount())) >= 0)
          {
            commitmentAmount = headerRow.getCommitmentAmount();
          }
          // 本体金額＋消費税額＜充当残高   → 充当金額＝本体金額＋消費税額
          else
          {
            commitmentAmount = totalItemEntered.add(totalTaxEntered);
          }
        }
        // 請求金額＝本体金額＋消費税額－充当金額
        totalEntered = new Number(totalEntered.sub(commitmentAmount));

        headerRow.setInvItemAmount(totalItemEntered);
        headerRow.setInvTaxAmount(totalTaxEntered);
        headerRow.setInvAmount(totalEntered);
        headerRow.setInvAccountedAmount(totalAccounted);
        headerRow.setInvPrepayAmount(commitmentAmount);
      } // fetchedLineRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // resetTotalAmount()

  /**
   * 機能通貨の精度の取得
   * @param
   * @return Number 精度
   */
  private Number getPrecision()
  {
    // 初期化処理
    String methodName = "getPrecision";
    startProcedure(getClass().getName(), methodName);
    
    // ビュー・オブジェクトの取得
    Xx03PrecisionVOImpl vo = getXx03PrecisionVO1();
    vo.executeQuery();
    vo.first();

    Xx03PrecisionVORowImpl row = (Xx03PrecisionVORowImpl)vo.getCurrentRow();

    // 終了処理
    endProcedure(getClass().getName(), methodName);

    return row.getPrecision();
  }

  // ver1.3 add start ---------------------------------------------------------
  /**
   * 画面で選択された通貨の精度の取得
   * @param String 通貨コード
   * @return Number 精度
   */
  private Number getSelectedPrecision(String currencyCode)
  {
    // 初期化処理
    String methodName = "getSelectedPrecision";
    startProcedure(getClass().getName(), methodName);
    
    // ビュー・オブジェクトの取得
    Xx03SelectedPrecisionVOImpl vo = getXx03SelectedPrecisionVO1();
    vo.initQuery(currencyCode);
    vo.first();

    Xx03SelectedPrecisionVORowImpl row = (Xx03SelectedPrecisionVORowImpl)vo.getCurrentRow();

    // 終了処理
    endProcedure(getClass().getName(), methodName);

    return row.getPrecision();
  }
  // ver1.3 add end -----------------------------------------------------------

  /**
   * 換算済金額の調整
   * @param headerRow ヘッダ行オブジェクト
   * @param coordinateId 調整対象行番号
   * @return なし
   */
  public void resetAccountedAmount(Xx03ReceivableSlipsVORowImpl headerRow, int coordinateId)
  {
    // 初期化処理
    String methodName = "resetAccountedAmount";
    startProcedure(getClass().getName(), methodName);

    Number coordinateValue = new Number(0);           // 換算済金額の調整額
    Number totalAccounted = new Number(0);            // 調整候補の換算済合計金額
    Number maxAccountedAmount = new Number(0);        // 調整候補の換算済金額
    Number absMaxAccountedAmount = new Number(0);     // 調整候補の換算済金額(絶対値)

    int fetchedLineRowCount = 0;
    RowSetIterator selectLineIter = null;   
    Xx03ReceivableSlipsLineVORowImpl lineRow = null;

     try
     {
      // ビュー・オブジェクトの取得
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedLineRowCount = lineVo.getFetchedRowCount();    
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if (fetchedLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);
      }
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);              
      }

      lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(coordinateId);

      // 調整額の算出
      coordinateValue = headerRow.getInvAccountedAmount().subtract(headerRow.getInvAmount());

      // 調整候補の換算済合計金額を算出
      totalAccounted = headerRow.getInvAccountedAmount();

      // 調整候補の換算済金額の絶対値を算出
      maxAccountedAmount = lineRow.getAccountedAmount();
      absMaxAccountedAmount = (Number)maxAccountedAmount.abs();

      // 調整
      if (coordinateValue.compareTo(0) != 0)
      {
        headerRow.setInvAccountedAmount(totalAccounted.subtract(coordinateValue));
        lineRow.setAccountedAmount(maxAccountedAmount.subtract(coordinateValue));  
      }

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
    }
  } // resetAccountedAmount()

  /**
   * 伝票番号の採番
   * @param num_type 仮/正区分
   * @param requestEnableFlag 申請可能フラグ
   * @return なし
   */
  public void publishNum(String num_type, String requestEnableFlag)
  {
    // 初期化処理
    String methodName = "publishNum";
    startProcedure(getClass().getName(), methodName);  

    Number receivableNum = new Number(0);    // 伝票番号
    
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;

     try
     {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //ver 11.5.10.2.7 Chg Start
      //Xx03SlipNumbersVOImpl slipNumVo = getXx03SlipNumbersVO1();
      Xx03SlipNumbersVOImpl slipNumVo = null;
      //ver 11.5.10.2.7 Chg End
     
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount

      Xx03SlipNumbersVORowImpl slipNumRow = null;

      //ver 11.5.10.2.7 Mov Start
      //処理のタイミングをロックと近づけるため移動
      ////Ver11.5.10.2.6C ADD Start
      //// 仮番号の接頭辞をVOから取得する
      //slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
      //slipNumVo.first();
      //slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
      //String tempCode = slipNumRow.getTemporaryCode();
      ////Ver11.5.10.2.6C ADD End
      //ver 11.5.10.2.7 Mov End

      // 保存時の仮伝票番号の採番
      if (Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE.compareTo(num_type) == 0)
      {
        //ver 11.5.10.2.7 Mov Start
        //処理のタイミングをロックと近づけるため移動
        //slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
        //slipNumVo.first();
        //slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
        //ver 11.5.10.2.7 Mov End
        
        if (Xx03ArCommonUtil.STR_NO.equals(headerRow.getRequestEnableFlag()))
        {
          headerRow.setRequestEnableFlag(requestEnableFlag);
        }

        // 仮伝票番号未作成のみ変更対象
        // ※" "にて初期作成
        if (" ".compareTo(headerRow.getReceivableNum()) == 0)
        {

          //ver 11.5.10.2.7 Add Start
          slipNumVo = getXx03SlipNumbersVO1();
          slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
          slipNumVo.first();
          slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();

          try
          {
            slipNumRow.lock();
          }
          catch (OAException ex)
          {
            if (   "FND".equals(ex.getProductCode())
                && "FND_LOCK_RECORD_ERROR".equals(ex.getMessageName())
                )
            {
              throw new OAException("XX03",
                                    "APP-XX03-14163",
                                    null,
                                    OAException.ERROR,
                                    null);
            }
            else
            {
              throw OAException.wrapperException(ex);
            }
          }
          //ver 11.5.10.2.7 Add End
          
          receivableNum = new Number(slipNumRow.getSlipNumber().intValue() + 1);
          headerRow.setReceivableNum(slipNumRow.getTemporaryCode() + receivableNum.toString());
          slipNumRow.setSlipNumber(receivableNum);
        }
      }
      // 申請時の正規伝票番号の採番
      else
      {
        //ver 11.5.10.2.7 Mov Start
        ////処理のタイミングをロックと近づけるため移動
        //slipNumVo.initQuery(Xx03ArCommonUtil.NON_TEMP_SLIP_NUM_TYPE);
        //slipNumVo.first();
        //slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
        //ver 11.5.10.2.7 Mov End
        
        if (Xx03ArCommonUtil.STR_NO.equals(headerRow.getRequestEnableFlag()))
        {
          headerRow.setRequestEnableFlag(requestEnableFlag);
        }

        //ver 11.5.10.2.7 Add Start
        slipNumVo = getXx03SlipNumbersVO1();
        // 仮番号の接頭辞をVOから取得する
        slipNumVo.initQuery(Xx03ArCommonUtil.TEMP_SLIP_NUM_TYPE);
        slipNumVo.first();
        slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();
        String tempCode = slipNumRow.getTemporaryCode();
        //ver 11.5.10.2.7 Mov End

        // 仮伝票番号か未作成のみ変更対象
        if (((headerRow.getReceivableNum().length() > 3) &&
        //Ver11.5.10.2.6C Change Start
        //仮番号の接頭辞をVOから取得した値に変更
        //  (headerRow.getReceivableNum().substring(0,3).compareTo(Xx03ArCommonUtil.TEMP_CODE) == 0))
          (headerRow.getReceivableNum().substring(0,3).compareTo(tempCode) == 0))
        //Ver11.5.10.2.6C Change End
          || (" ".compareTo(headerRow.getReceivableNum()) == 0))
        {

          //ver 11.5.10.2.7 Add Start
          slipNumVo.initQuery(Xx03ArCommonUtil.NON_TEMP_SLIP_NUM_TYPE);
          slipNumVo.first();
          slipNumRow = (Xx03SlipNumbersVORowImpl)slipNumVo.getCurrentRow();

          try
          {
            slipNumRow.lock();
          }
          catch (OAException ex)
          {
            if (   "FND".equals(ex.getProductCode())
                && "FND_LOCK_RECORD_ERROR".equals(ex.getMessageName())
                )
            {
              throw new OAException("XX03",
                                    "APP-XX03-14163",
                                    null,
                                    OAException.ERROR,
                                    null);
            }
            else
            {
              throw OAException.wrapperException(ex);
            }
          }
          //ver 11.5.10.2.7 Add End

          receivableNum = new Number(slipNumRow.getSlipNumber().intValue() + 1);
          headerRow.setReceivableNum(receivableNum.toString());
          slipNumRow.setSlipNumber(receivableNum);
        }
      }

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // publishNum()

  /**
   * 支払予定日取得
   * @param なし
   * @return なし
   */
  public void getDueDate()
  {
    // 初期化処理
    String methodName = "getDueDate";
    startProcedure(getClass().getName(), methodName);

    // ビュー・オブジェクトの取得
    int fetchedHeaderRowCount;
    RowSetIterator selectHeaderIter = null;
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();

    try
    {
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
      // 支払期日の算出
      if ((headerRow.getTermsId() != null) && (headerRow.getInvoiceDate() != null))
      {
        Date dueDate = calcDueDate(headerRow.getTermsId(), headerRow.getInvoiceDate());
        headerRow.setPaymentScheduledDate(dueDate);
      }

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // getDueDate()

  /**
   * 伝票の保存
   * @param なし
   * @return なし
   */
  public void save()
  {
    // 初期化処理
    String methodName = "save";
    startProcedure(getClass().getName(), methodName);

    // 一見顧客フラグが'Y'以外の時は一見顧客情報カラムの内容をクリア
    // ビュー・オブジェクトの取得
    int fetchedHeaderRowCount;
    RowSetIterator selectHeaderIter = null;
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();

    try
    {
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      // 一見顧客フラグチェック
      String firstCustomerFlag = headerRow.getFirstCustomerFlag();
      if ((firstCustomerFlag == null) || (!firstCustomerFlag.equals(Xx03ArCommonUtil.STR_YES))){
        // 一見顧客区分'Y'以外の場合、一見顧客情報クリア
        headerRow.setOnetimeCustomerName(null);
        headerRow.setOnetimeCustomerKanaName(null);
        headerRow.setOnetimeCustomerAddress1(null);
        headerRow.setOnetimeCustomerAddress2(null);
        headerRow.setOnetimeCustomerAddress3(null);
      }

      try
      {
        // COMMIT
        getTransaction().commit();
      }
      catch(OAException ex)
      {
        throw OAException.wrapperException(ex);
      }

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // save()

  /**
   * 明細のコピー
   * @param なし
   * @return なし
   */
  public void copyLine()
  {
    // 初期化処理
    String methodName = "copyLine";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectIter = null;

    //Ver11.5.10.2.6B Add Start
    RowSetIterator selectIter2 = null;
    int addRowFlag = 0;
    int addRowIdx  = 0;
    //Ver11.5.10.2.6B Add End

    int fetchedRowCount;
    int rowCount;
    int nocheck = 0;

    //Ver11.5.10.1.6M Add Start
    removeEmptyRows();
    //Ver11.5.10.1.6M Add End

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (lineVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      Row newLineRow = null; 

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End

      selectIter = lineVo.createRowSetIterator("selectIter");
      //Ver11.5.10.2.6B Add Start
      selectIter2 = lineVo.createRowSetIterator("selectIter2");
      //Ver11.5.10.2.6B Add End

      if (fetchedRowCount > 0)
      {
// ver1.2 Add Start コピー方式をGL方式に変更
        Vector deleteLineIdx = new Vector();
// ver1.2 Add End
        
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

// ver1.2 Change Start コピー方式をGL方式に変更
//        for (int i=fetchedRowCount-1; i>=0; i--)
        for (int i=0; i<fetchedRowCount; i++)
// ver1.2 Change End
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

// ver1.2 Delete Start コピー方式をGL方式に変更
//          // 挿入位置
//          // 自分の下にコピーする
//          lineVo.setCurrentRowAtRangeIndex(i);
//          lineVo.next();
// ver1.2 Delete End

          if (lineRow != null)
          {
            Number receivableLineId = lineRow.getReceivableLineId();
            Number receivableId = lineRow.getReceivableId();
            String selectSwitcher = lineRow.getSelectSwitcher();

            //Ver11.5.10.2.3C Add Start
            lineRow.setSelectSwitcher(null);
            //Ver11.5.10.2.3C Add End

            // 初期値より変更していない場合(空白行）
            if (!lineRow.isInput())
            {
// ver1.2 Change Start コピー方式をGL方式に変更
//              lineRow.remove();
              deleteLineIdx.add(new Integer(i));
// ver1.2 Change End
              nocheck++;
            }
            // 初期値より変更している場合
            else
            {
              if ((selectSwitcher == null) || (receivableId == null))
              {
                nocheck++;
              }
              else if ((Xx03ArCommonUtil.STR_YES.compareTo(selectSwitcher)) == 0)
              {
                //Ver11.5.10.2.6B Chg Start
                //lineVo.last();
                //lineVo.next();
                selectIter2.last();
                selectIter2.next();
                //Ver11.5.10.2.6B Chg End

                //Ver11.5.10.1.6M Change Start
                try
                {
                  //Ver11.5.10.2.6B Chg Start
                  //newLineRow = lineVo.createAndInitRow(lineRow);
                  //newLineRow.setAttribute("LineNumber", new Number(fetchedRowCount+i+1));
                  //lineVo.insertRow(newLineRow);
                  newLineRow = selectIter2.createAndInitRow(lineRow);
                  newLineRow.setAttribute("LineNumber", new Number(fetchedRowCount+i+1));
                  selectIter2.insertRow(newLineRow);
                  
                  if (addRowFlag == 0)
                  {
                    lineVo.last();
                    addRowIdx  = lineVo.getCurrentRowIndex();
                    addRowFlag = 1;
                  }
                  //Ver11.5.10.2.6B Chg End
                }
                catch(Exception e) 
                {
                  newLineRow.remove();
                  throw OAException.wrapperException(e);
                }
                //Ver11.5.10.1.6M Change End
              }
              else
              {
                nocheck++;
              }
            }
          } // lineRow != null
        } // for loop

        if (fetchedRowCount == nocheck)
        {
          throw new OAException("XX03",
                                "APP-XX03-13050",
                                null,
                                OAException.ERROR,
                                null);
        }

// ver1.2 Add Start コピー方式をGL方式に変更
        // 空行を削除
        for (int i=deleteLineIdx.size()-1; i>=0; i--)
        {
          int deleteIdx = Integer.parseInt(deleteLineIdx.elementAt(i).toString());
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(deleteIdx);
          lineRow.remove();
        } // for loop
// ver1.2 Add End

        //Ver11.5.10.2.6B Add Start
        lineVo.setRangeSize(5);
        addRowIdx = addRowIdx - addRowIdx % 5;
        lineVo.setRangeStart(addRowIdx);
        //Ver11.5.10.2.6B Add End

      } // fetchedRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
      //Ver11.5.10.2.6B Add Start
      if(selectIter2 != null)
      {
        selectIter2.closeRowSetIterator();
      }
      //Ver11.5.10.2.6B Add End
    }
  } // copyLine()

  /**
   * 明細の削除
   * @param なし
   * @return なし
   */
  public void deleteLine()
  {
    // 初期化処理
    String methodName = "deleteLine";
    startProcedure(getClass().getName(), methodName);  

    RowSetIterator selectIter = null;
    int fetchedRowCount;
    int nocheck = 0;

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectIter = lineVo.createRowSetIterator("selectIter");
    
      if (fetchedRowCount > 0)
      {
        Vector deleteLineIdx = new Vector();
        
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=fetchedRowCount-1; i>=0; i--)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedReceivableId = lineRow.getReceivableId();
            String cachedSelectSwitcher = lineRow.getSelectSwitcher();
            
            // 初期値より変更していない場合(空白行）
            if (!lineRow.isInput())
            {
              lineRow.remove();
              nocheck++;
            }
            // 初期値より変更している場合
            else
            {
              if ((cachedSelectSwitcher == null) || (cachedReceivableId == null))
              {     
                nocheck++;
              }
              else if ((Xx03ArCommonUtil.STR_YES.compareTo(cachedSelectSwitcher)) == 0)  
              {
                lineRow.remove();
              }
              else
              {
                nocheck++;
              }
            }
          } // lineRow != null
        } // for loop

        if (fetchedRowCount == nocheck)
        {
          throw new OAException("XX03",
                                "APP-XX03-13050",
                                null,
                                OAException.ERROR,
                                null);
        }
      } // fetchedRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // deleteLine()

  /**
   * 振替伝票明細の追加
   * @param slipType 伝票種別
   * @return なし
   */
  public void addReceivableSlipLines()
  {
    // 初期化処理
    String methodName = "addReceivableSlipLines";
    startProcedure(getClass().getName(), methodName);

    // 明細行作成
    createReceivableDetailLines(5, true);

    // 終了処理
    endProcedure(getClass().getName(), methodName);    
  } // addReceivableSlipLines()

  /**
   * 明細番号の採番
   * @param なし
   * @return なし
   */
  public void resetLineNumber()
  {
    // 初期化処理
    String methodName = "resetLineNumber";
    startProcedure(getClass().getName(), methodName);

    Number newLineNumber = new Number(1);
    RowSetIterator selectIter = null;
    int fetchedRowCount;

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (lineVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedLineNumber = lineRow.getLineNumber();
            String cachedSegment1 = lineRow.getSegment1();
            newLineNumber = new Number(i+1);
          
            if (cachedLineNumber.compareTo(newLineNumber) != 0)
            {
              ((Xx03ReceivableSlipsLineVORowImpl)lineRow).setLineNumber(new Number(i+1));          

              // 要修正
              // 修正中か否かを判断する方法
              // 判断用のカラムの追加？
              if (cachedSegment1 == null)
              {
                lineRow.setNewRowState(Row.STATUS_INITIALIZED);
              }
            }
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // resetLineNumber()

  /**
   * 自動会計取得
   * @param なし
   * @return なし
   */
  public void getAutoAccounting()
  {
    // 初期化処理
    String methodName = "getAutoAccounting";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectIter = null;
    int fetchedHeaderRowCount;
    int fetchedRowCount;
    int rowCount;

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (headerVo ==null || lineVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      String entryDepartment = null;
      Number customerId = null;
      Number customerOfficeId = null;
      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          entryDepartment = headerRow.getEntryDepartment();
          customerId = headerRow.getCustomerId();
          customerOfficeId = headerRow.getCustomerOfficeId();
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      Row newLineRow = null; 

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedReceivableId = lineRow.getReceivableId();
            String cachedSelectSwitcher = lineRow.getSelectSwitcher();
 
            if ((cachedSelectSwitcher == null) || (cachedReceivableId == null))
            {     
            }
            else if ((Xx03ArCommonUtil.STR_YES.compareTo(cachedSelectSwitcher)) == 0)
            {
              getAutoAccountingData(entryDepartment, customerId, customerOfficeId, lineRow);
            }
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // getAutoAccounting()

  /**
   * 自動会計取得(タブ押下時)
   * @param なし
   * @return なし
   */
  public void getAutoAccountingTab()
  {
    // 初期化処理
    String methodName = "getAutoAccountingTab";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectIter = null;
    int fetchedHeaderRowCount;
    int fetchedRowCount;
    int rowCount;

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      if (headerVo ==null || lineVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      String entryDepartment = null;
      Number customerId = null;
      Number customerOfficeId = null;
      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          entryDepartment = headerRow.getEntryDepartment();
          customerId = headerRow.getCustomerId();
          customerOfficeId = headerRow.getCustomerOfficeId();
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;
      Row newLineRow = null; 

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End

      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if ((lineRow != null) &&
              ((lineRow.getSlipLineType() != null) && (!"".equals(lineRow.getSlipLineType().toString()))) &&
              ((lineRow.getSegment1() == null) || ("".equals(lineRow.getSegment1()))) &&
              ((lineRow.getSegment2() == null) || ("".equals(lineRow.getSegment2()))) &&
              ((lineRow.getSegment3() == null) || ("".equals(lineRow.getSegment3()))) &&
              ((lineRow.getSegment4() == null) || ("".equals(lineRow.getSegment4()))) &&
              ((lineRow.getSegment5() == null) || ("".equals(lineRow.getSegment5()))) &&
              ((lineRow.getSegment6() == null) || ("".equals(lineRow.getSegment6()))) &&
              ((lineRow.getSegment7() == null) || ("".equals(lineRow.getSegment7()))) &&
              ((lineRow.getSegment8() == null) || ("".equals(lineRow.getSegment8())))
             )
          {
            Number cachedReceivableLineId = lineRow.getReceivableLineId();
            Number cachedReceivableId = lineRow.getReceivableId();
            String autoTaxExec = lineRow.getAutoTaxExec();    // 自動会計実行済フラグ
 
            if ((cachedReceivableId == null))
            {     
            }
            else if ((autoTaxExec != null) && (!autoTaxExec.equals("Y")))
            {
              // 自動会計未実行
              getAutoAccountingData(entryDepartment, customerId, customerOfficeId, lineRow);
            }
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // getAutoAccountingTab()

  /**
   * 自動会計情報取得
   * @param entryDepartment 所属部門コード
   * @param customerId 顧客ID
   * @param customerOfficeId 顧客事業所ID
   * @param lineRow 明細行
   * @return なし
   */
  public void getAutoAccountingData(String entryDepartment, Number customerId, 
     Number customerOfficeId, Xx03ReceivableSlipsLineVORowImpl lineRow)
  {
    // 初期化処理
    String methodName = "getAutoAccountingData";
    startProcedure(getClass().getName(), methodName);

/*
    // 会社
    lineRow.setSegment1("100");
*/

    // 部門
    if (entryDepartment != null)
    {
      lineRow.setSegment2(entryDepartment); 
    }

    // 勘定科目、補助科目
    Number memoLineId = lineRow.getSlipLineType();  // メモ明細ID
    if (memoLineId != null)
    {
      Xx03GetAutoAccountInfoMemoVOImpl vo = getXx03GetAutoAccountInfoMemoVO1();
      Xx03GetAutoAccountInfoMemoVORowImpl row = null;
      vo.initQuery(memoLineId);
      row = (Xx03GetAutoAccountInfoMemoVORowImpl)vo.first();
      if (row != null)
      {
        lineRow.setSegment1(row.getSegment1());
//        lineRow.setSegment2(row.getSegment2());
        lineRow.setSegment3(row.getSegment3());
        lineRow.setSegment4(row.getSegment4());
        lineRow.setSegment6(row.getSegment6());
        lineRow.setSegment7(row.getSegment7());
        lineRow.setSegment8(row.getSegment8()); 
      }
    }

    // 相手先
    if ((customerId != null) && (customerOfficeId != null))
    {
      Xx03GetAutoAccountInfoCustomerVOImpl vo = getXx03GetAutoAccountInfoCustomerVO1();
      Xx03GetAutoAccountInfoCustomerVORowImpl row = null;
      vo.initQuery(customerId, customerOfficeId);
      row = (Xx03GetAutoAccountInfoCustomerVORowImpl)vo.first();
      if (row != null)
      {
        lineRow.setSegment5(row.getSegment5());
      }
    }

/*
    // 事業区分
    lineRow.setSegment6("090");

    // プロジェクト
    lineRow.setSegment7("0");

    // 予備
    lineRow.setSegment8("0");
*/

    // 自動会計実行済フラグ
    lineRow.setAutoTaxExec(Xx03ArCommonUtil.STR_YES);
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // getAutoAccounting()

  /**
   * 前受金ボタン表示区分取得
   * @param なし
   * @return 前受金表示区分
   */
  public String getPrePayButton()
  {
    // 初期化処理
    String methodName = "getPrePayButton";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;     
    int fetchedHeaderRowCount;
    String retStr = "N";  // 前受金表示区分

    try
    {
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      Xx03PrePayButtonVOImpl prepayVo = getXx03PrePayButtonVO1();
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      Xx03PrePayButtonVORowImpl prepayRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){
          // 伝票種別取得
          String slipType = headerRow.getSlipType();
      
          // 前受金表示区分取得
          prepayVo.initQuery(slipType);
          prepayRow = (Xx03PrePayButtonVORowImpl)prepayVo.first();
          retStr = prepayRow.getAttribute12();
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount 
    
      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
    return retStr;
  } // getPrePayButton() 

  /**
   * 上書の許可システムオプション取得
   * @param なし
   * @return 上書の許可システムオプション値
   */
  public String getTaxOverride()
  {
    // 初期処理
    String methodName = "getTaxOverride";
    startProcedure(getClass().getName(), methodName);
    
    String retValue = null;
    
    // 上書の許可システムオプションを取得する
    Xx03GetTaxOverrideVOImpl vo = getXx03GetTaxOverrideVO1();
    vo.executeQuery();
    vo.first();
    Xx03GetTaxOverrideVORowImpl row =
      (Xx03GetTaxOverrideVORowImpl)vo.getCurrentRow();
    retValue = row.getTaxRoundingAllowOverride();
    if(retValue == null)
    {
      retValue = "";
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);  
    return retValue;
  } // getTaxOverride()

  /**
   *
   * 機能通貨の取得
   *
   * @return  機能通貨
   */
  private String getCurrencyCode()
  {
    // 初期化処理
    String methodName = "getCurrencyCode";
    startProcedure(getClass().getName(), methodName);

    Xx03PrecisionVORowImpl row = null;

    try
    {
      // ビュー・オブジェクトの取得
      Xx03PrecisionVOImpl vo = getXx03PrecisionVO1();
      vo.executeQuery();
      vo.first();

      row = (Xx03PrecisionVORowImpl)vo.getCurrentRow();
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return row.getCurrencyCode();
  } // getCurrencyCode

  /**
   * 顧客、顧客事業所の消費税計算レベル、消費税端数処理を取得する
   * @param customerId 顧客ID
   * @param customerOfficeId 顧客事業所ID
   */
  private Hashtable getCustomerTaxOption(Number customerId, Number customerOfficeId)
  {
    // 初期化処理
    String methodName = "getCustomerTaxOption";
    startProcedure(getClass().getName(), methodName);

    Hashtable returnHashTable = new Hashtable();
    String taxCalcFlag = "";
    String taxRoundingRule = "";

    // 顧客、顧客事業所の消費税計算レベル、消費税端数処理取得
    // ビュー・オブジェクトの取得
    Xx03CustTaxOptionVOImpl vo = getXx03CustTaxOptionVO1();
    vo.initQuery(customerId, customerOfficeId);

    if (vo != null)
    {
      // VO not null
      Xx03CustTaxOptionVORowImpl row = (Xx03CustTaxOptionVORowImpl)vo.first();
      if (row != null)
      {
        // ROW not null
        //Ver11.5.10.1.5B 2005/09/27 Change Start
        // 消費税計算レベル取得
        if ((row.getTaxHeaderLevelFlag() != null) 
          && (!row.getTaxHeaderLevelFlag().equals("")))
        {
          // 顧客事業所の消費税計算レベル値あり
          taxCalcFlag = row.getTaxHeaderLevelFlag();
        }
        else
        {
          // 顧客事業所の消費税計算レベル値なし → 顧客の消費税計算レベル値取得
          if ((row.getTaxHeaderLevelFlagC() != null) 
            && (!row.getTaxHeaderLevelFlagC().equals("")))
          {
            // 顧客の消費税計算レベル値あり
            taxCalcFlag = row.getTaxHeaderLevelFlagC();
          }
        }

        // 消費税端数処理取得
        if ((row.getTaxRoundingRule() != null) 
            && (!row.getTaxRoundingRule().equals("")))
        {
          // 顧客事業所の消費税端数処理値あり
          taxRoundingRule = row.getTaxRoundingRule();
        }
        else
        {
          // 顧客事業所の消費税端数処理値なし → 顧客の消費税端数処理値取得
          if ((row.getTaxRoundingRuleC() != null) 
            && (!row.getTaxRoundingRuleC().equals("")))
          {
            // 顧客の消費税端数処理値あり
            taxRoundingRule = row.getTaxRoundingRuleC();
          }
        }
        // // 顧客事業所の値取得
        //if ((row.getTaxHeaderLevelFlag() != null) 
        //    && (!row.getTaxHeaderLevelFlag().equals(""))
        //    && (row.getTaxRoundingRule() != null)
        //    && (!row.getTaxRoundingRule().equals("")))
        //{
        //  // 顧客事業所の消費税オプション値あり
        //  taxCalcFlag = row.getTaxHeaderLevelFlag();
        //  taxRoundingRule = row.getTaxRoundingRule();
        //}
        //else
        //{
        //  // 顧客事業所の消費税オプション値なし → 顧客の消費税オプション値取得
        //  if ((row.getTaxHeaderLevelFlagC() != null) 
        //      && (!row.getTaxHeaderLevelFlagC().equals(""))
        //      && (row.getTaxRoundingRuleC() != null)
        //      && (!row.getTaxRoundingRuleC().equals("")))
        //  {
        //    // 顧客の消費税オプション値あり
        //    taxCalcFlag = row.getTaxHeaderLevelFlagC();
        //    taxRoundingRule = row.getTaxRoundingRuleC();
        //  }
        //}
        //Ver11.5.10.1.5B 2005/09/27 Change End
      }
    }

    // 戻り値セット
    returnHashTable.put("taxCalcFlag", taxCalcFlag);
    returnHashTable.put("taxRoundingRule", taxRoundingRule);
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return returnHashTable;
  } // getCustomerTaxOption

  /**
   * システムオプションの消費税計算レベル、消費税端数処理を取得する
   */
  private Hashtable getSystemTaxOption()
  {
    // 2006/01/23 Ver11.5.10.1.6L Add Start
    OADBTransaction txn = getOADBTransaction();
    // 2006/01/23 Ver11.5.10.1.6L Add End
    // 初期化処理
    String methodName = "getSystemTaxOption";
    startProcedure(getClass().getName(), methodName);

    Hashtable returnHashTable = new Hashtable();
    String taxCalcFlag = "";
    String taxRoundingRule = "";

    // 顧客、顧客事業所の消費税計算レベル、消費税端数処理取得
    // ビュー・オブジェクトの取得
    Xx03SystemTaxOptionVOImpl vo = getXx03SystemTaxOptionVO1();
    vo.executeQuery();
    Xx03SystemTaxOptionVORowImpl row = (Xx03SystemTaxOptionVORowImpl)vo.first();
    if (row != null)
    {
      // ROW not null
      if ((row.getTaxHeaderLevelFlag() != null) 
          && (!row.getTaxHeaderLevelFlag().equals(""))
          && (row.getTaxRoundingRule() != null)
          && (!row.getTaxRoundingRule().equals("")))
      {
        // システムオプション値あり
        taxCalcFlag = row.getTaxHeaderLevelFlag();
        taxRoundingRule = row.getTaxRoundingRule();
      }
      else
      {
        // システムオプション値なし
        // 2006/01/23 Ver11.5.10.1.6L Change Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", Xx03ArCommonUtil.MESSAGE_STR_GL_TAX_INFO)};
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", txn.getMessage("XX03","APP-XX03-34062",null))};
        // 2006/01/23 Ver11.5.10.1.6L Change End
        throw new OAException("XX03","APP-XX03-13036", tokens);
      }
    }
    else
    {
      // システムオプション値なし
      // 2006/01/23 Ver11.5.10.1.6L Change Start
      //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", Xx03ArCommonUtil.MESSAGE_STR_GL_TAX_INFO)};
      MessageToken[] tokens = {new MessageToken("OBJECT_NAME", txn.getMessage("XX03","APP-XX03-34062",null))};
      // 2006/01/23 Ver11.5.10.1.6L Change End
      throw new OAException("XX03","APP-XX03-13036", tokens);
    }

    // 戻り値セット
    returnHashTable.put("taxCalcFlag", taxCalcFlag);
    returnHashTable.put("taxRoundingRule", taxRoundingRule);
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return returnHashTable;
  } // getSystemTaxOption

  /**
   *
   * 伝票種別の取得
   *
   * @param   slipTypeCode  伝票種別コード
   * @return  精度
   */
  public Serializable getSlipTypeName(String slipTypeCode)
  {
    // 初期化処理
    String methodName = "getSlipTypeName";
    startProcedure(getClass().getName(), methodName);

    Xx03SlipTypesLovVORowImpl row = null;

    try
    {
      // ビュー・オブジェクトの取得
      Xx03SlipTypesLovVOImpl vo = getXx03SlipTypesLovVO1();
      vo.initQuery(slipTypeCode);
      vo.first();

      row = (Xx03SlipTypesLovVORowImpl)vo.getCurrentRow();
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return row.getDescription();
  } // getSlipTypeName

  /**
   *
   * 伝票の変更取消
   */
  public void rollback()
  {
    // 初期化処理
    String methodName = "rollback";
    startProcedure(getClass().getName(), methodName);

    try
    {
      Transaction txn = getTransaction();

      if (txn.isDirty())
      {
        txn.rollback();
      }
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // rollback()

  /**
   * 前受充当伝票使用チェック
   * @param commitmentNumber チェック対象前受充当伝票番号
   * @param receivableNum チェック対象伝票番号
   * @return  該当前受充当伝票を使用中の伝票番号
   */
  public String checkCommitmentNumber(String commitmentNumber, String receivableNum)
  {
    // 初期化処理
    String methodName = "checkCommitmentNumber";
    startProcedure(getClass().getName(), methodName);

    String retReceivableNum = null;

    // ビュー・オブジェクトの取得
    Xx03CheckCommitmentNumberVOImpl checkVo = getXx03CheckCommitmentNumberVO1();
    checkVo.initQuery(commitmentNumber);

    if (checkVo.getRowCount() > 0)
    {
      // チェック対象前受充当伝票を使用している伝票がある
      Xx03CheckCommitmentNumberVORowImpl checkRow = (Xx03CheckCommitmentNumberVORowImpl)checkVo.first();
      retReceivableNum = checkRow.getReceivableNum();
      if (retReceivableNum.equals(receivableNum))
      {
        // 該当レコードは自レコード
        retReceivableNum = null;
      }
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return retReceivableNum;
  } // checkCommitmentNumber

  /**
   * 画面金額表示フォーマット
   * @param なし
   * @return なし
   */
  public void formatAmount()
  {
    // 初期化処理
    String methodName = "formatAmount";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectHeaderIter = null;     
    int fetchedHeaderRowCount;
    String retStr = "N";  // 前受金表示区分

    try
    {
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      Xx03ReceivableSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");
      Xx03GetBaseCurrencyVOImpl baseCurVo = getXx03GetBaseCurrencyVO1();
      baseCurVo.executeQuery();
      Xx03GetBaseCurrencyVORowImpl baseCurRow = (Xx03GetBaseCurrencyVORowImpl)baseCurVo.first();

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        if (headerRow != null){

          //ver 11.5.10.2.10B Add Start
          XX03GetItemFormatVOImpl    formatVo  = getXX03GetItemFormatVO1();
          XX03GetItemFormatVORowImpl formatRow = null;
          //ver 11.5.10.2.10B Add End

          // 通貨コード取得
          String curCode = headerRow.getInvoiceCurrencyCode();  // 選択中通貨コード
          String baseCurCode = baseCurRow.getCurrencyCode();    // 機能通貨コード

          // 請求合計金額フォーマット
          //ver 11.5.10.2.10B Chg Start
          //String strInvAmount = 
          //  getFormatCurrencyString(headerRow.getInvAmount(), curCode);
          //headerRow.setDispInvAmount(strInvAmount);
          formatVo.initQuery(curCode, headerRow.getInvAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // 換算済合計金額フォーマット
          //String strInvAccountedAmount = 
          //  getFormatCurrencyString(headerRow.getInvAccountedAmount(), baseCurCode);
          //headerRow.setDispInvAccountedAmount(strInvAccountedAmount);
          formatVo.initQuery(baseCurCode, headerRow.getInvAccountedAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvAccountedAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // 本体合計金額フォーマット
          //String strInvItemAmount = 
          //  getFormatCurrencyString(headerRow.getInvItemAmount(), curCode);
          //headerRow.setDispInvItemAmount(strInvItemAmount);
          formatVo.initQuery(curCode, headerRow.getInvItemAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvItemAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // 消費税合計金額フォーマット
          //String strInvTaxAmount = 
          //  getFormatCurrencyString(headerRow.getInvTaxAmount(), curCode);
          //headerRow.setDispInvTaxAmount(strInvTaxAmount);
          formatVo.initQuery(curCode, headerRow.getInvTaxAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvTaxAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

          //ver 11.5.10.2.10B Chg Start
          // 充当金額フォーマット
          //String strInvPrepayAmount = 
          //  getFormatCurrencyString(headerRow.getInvPrepayAmount(), curCode);
          //headerRow.setDispInvPrepayAmount(strInvPrepayAmount);
          formatVo.initQuery(curCode, headerRow.getInvPrepayAmount());
          formatRow = (XX03GetItemFormatVORowImpl)formatVo.first();
          headerRow.setDispInvPrepayAmount(formatRow.getFormatItem());
          //ver 11.5.10.2.10B Chg End

        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // fetchedHeaderRowCount 
      
      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // formatAmount

  /**
   * 金額フォーマット
   * @param numAmount フォーマット対象金額
   * @param currencyCode フォーマット通貨コード
   * @return フォーマット済文字列
   */
  public String getFormatCurrencyString(Number numAmount, String currencyCode)
  {
    // 初期化処理
    String methodName = "getFormatCurrencyString";
    startProcedure(getClass().getName(), methodName);
    
    String strAmount = null;  // Return用文字列

    if (numAmount != null || currencyCode != null)
    {
      // パラメータNull以外の時のみチェック
      try
      {
        strAmount = numAmount.toString();

        // OANLSServices取得
        OADBTransaction transaction = getOADBTransaction();
        OANLSServices nlsService = new OANLSServices(transaction);
        // 金額フォーマット
        strAmount = nlsService.formatCurrency(numAmount, currencyCode); 
      }
      catch (SQLException sqlex)
      {
        throw new OAException(sqlex.getMessage());
      }
    }
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return strAmount;
  } // getFormatCurrencyString

  /**
   * AFF,DFFプロンプト取得(AR部門入力、入力画面)
   * @param なし
   * @return AFFプロンプト
   */
  public ArrayList getAFFPromptArInput()
  {
    // 初期化処理
    String methodName = "getAFFPromptArInput";
    startProcedure(getClass().getName(), methodName);

    ArrayList returnInfo = new ArrayList();

    String segment1Prompt = null;
    String segment2Prompt = null;
    String segment3Prompt = null;
    String segment4Prompt = null;
    String segment5Prompt = null;
    String segment6Prompt = null;
    String segment7Prompt = null;
    String segment8Prompt = null;
    String attribute1Prompt = null;
    String attribute2Prompt = null;

    // AFFプロンプト取得
    Xx03GetAffPromptVOImpl affVo = getXx03GetAffPromptVO1();
    Xx03GetAffPromptVORowImpl affRow = null;
    affVo.executeQuery();
    affRow = (Xx03GetAffPromptVORowImpl)affVo.first();
    if (affRow != null)
    {
      segment1Prompt = affRow.getSegment1Prompt();
      segment2Prompt = affRow.getSegment2Prompt();
      segment3Prompt = affRow.getSegment3Prompt();
      segment4Prompt = affRow.getSegment4Prompt();
      segment5Prompt = affRow.getSegment5Prompt();
      segment6Prompt = affRow.getSegment6Prompt();
      segment7Prompt = affRow.getSegment7Prompt();
      segment8Prompt = affRow.getSegment8Prompt();
    }
    returnInfo.add(segment1Prompt);
    returnInfo.add(segment2Prompt);
    returnInfo.add(segment3Prompt);
    returnInfo.add(segment4Prompt);
    returnInfo.add(segment5Prompt);
    returnInfo.add(segment6Prompt);
    returnInfo.add(segment7Prompt);
    returnInfo.add(segment8Prompt);

    // DFFプロンプト取得
    // オルグ名称取得
    String orgName = getOrgname();
    Xx03GetDffPromptVOImpl dffVo = getXx03GetDffPromptVO1();
    Xx03GetDffPromptVORowImpl dffRow = null;
    dffVo.initQuery(Xx03ArCommonUtil.DFF_PROMPT_DFF_NAME,
                      orgName,
                      Xx03ArCommonUtil.DFF_PROMPT_ATTRIBUTE1,
                      Xx03ArCommonUtil.DFF_PROMPT_ATTRIBUTE2);
    dffRow = (Xx03GetDffPromptVORowImpl)dffVo.first();
    if (dffRow != null)
    {
      attribute1Prompt = dffRow.getAttribute1Prompt();
      attribute2Prompt = dffRow.getAttribute2Prompt();
    }
    returnInfo.add(attribute1Prompt);
    returnInfo.add(attribute2Prompt);
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);    
    return returnInfo;
  } // getAFFPromptArInput()

  // ver 1.2 Add Start 内税フラグを税コードから取得
  /**
   * 内税フラグ取得
   * @param 税コード
   * @return 内税フラグ
   */
  //Ver11.5.10.1.6E 2005/12/26 Change Start
//  public String getIncludesTaxFlag(String taxCode)
  public String getIncludesTaxFlag(String taxCode, Date invDate)
  //Ver11.5.10.1.6E 2005/12/26 Change End
  {
    // 初期化処理
    String methodName = "getIncludesTaxFlag";
    startProcedure(getClass().getName(), methodName);
    
    // ビュー・オブジェクトの取得
    Xx03TaxClassLovVOImpl vo = getXx03TaxClassLovVO1();
    //Ver11.5.10.1.6E 2005/12/26 Change Start
    //vo.initQuery(taxCode);
    //vo.first();
    //Xx03TaxClassLovVORowImpl row = (Xx03TaxClassLovVORowImpl)vo.getCurrentRow();
    //String retStr = row.getAmountIncludesTaxFlag();
    String retStr = "";
    vo.initQuery(taxCode, invDate);
    if (vo.first() != null)
    {
      Xx03TaxClassLovVORowImpl row = (Xx03TaxClassLovVORowImpl)vo.getCurrentRow();
      retStr = row.getAmountIncludesTaxFlag();
    }
    //Ver11.5.10.1.6E 2005/12/26 Change End    
    // 終了処理
    endProcedure(getClass().getName(), methodName);    
    return retStr;
  } // getIncludesTaxFlag()

  //Ver11.5.10.1.6P Chg Start
  /**
   * 税ID取得
   * @param  税コード
   * @param  請求書日付
   * @return 税ID
   */
  public Number getTaxId(String taxCode, Date invDate)
  {
    // 初期化処理
    String methodName = "getTaxId";
    startProcedure(getClass().getName(), methodName);
    
    // ビュー・オブジェクトの取得
    Xx03TaxClassLovVOImpl vo = getXx03TaxClassLovVO1();
    Number retNum = null;
    vo.initQuery(taxCode, invDate);
    if (vo.first() != null)
    {
      Xx03TaxClassLovVORowImpl row = (Xx03TaxClassLovVORowImpl)vo.getCurrentRow();
      retNum = row.getVatTaxId();
    }
    // 終了処理
    endProcedure(getClass().getName(), methodName);    
    return retNum;
  } // getTaxId()
  //Ver11.5.10.1.6P Chg End

  /**
   * 内税フラグ設定
   * @param なし
   * @return なし
   */
  public void setIncludesTaxFlag()
  {
    // 初期化処理
    String methodName = "setIncludesTaxFlag";
    startProcedure(getClass().getName(), methodName);  
    
    RowSetIterator selectIter = null;
    int fetchedRowCount;
    int rowCount;

    //Ver11.5.10.1.6E 2005/12/26 Add Start
    Date headInvDate = null;
    //Ver11.5.10.1.6E 2005/12/26 Add End

    try
    {
      // ビュー・オブジェクトの取得
      //Ver11.5.10.1.6E 2005/12/26 Add Start
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      if (headerVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      Xx03ReceivableSlipsVORowImpl headerRow = null;
      headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();
      headInvDate = headerRow.getInvoiceDate();
      //Ver11.5.10.1.6E 2005/12/26 Add End
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();
      if (lineVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
    
      Xx03ReceivableSlipsLineVORowImpl lineRow = null;

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedRowCount = lineVo.getFetchedRowCount();
      fetchedRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End

      selectIter = lineVo.createRowSetIterator("selectIter");

      if (fetchedRowCount > 0)
      {
        selectIter.setRangeStart(0);
        selectIter.setRangeSize(fetchedRowCount);

        for (int i=0; i<fetchedRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);

          if ((lineRow != null) &&
              ((lineRow.getTaxCode() != null) && (!"".equals(lineRow.getTaxCode().toString()))))
          {
            //Ver11.5.10.1.6E 2005/12/26 Change Start
//            lineRow.setAmountIncludesTaxFlag(getIncludesTaxFlag(lineRow.getTaxCode()));
            lineRow.setAmountIncludesTaxFlag(getIncludesTaxFlag(lineRow.getTaxCode(),headInvDate));
            //Ver11.5.10.1.6E 2005/12/26 Change End
            //Ver11.5.10.1.6P Add Start
            lineRow.setTaxId(getTaxId(lineRow.getTaxCode(),headInvDate));
            //Ver11.5.10.1.6P Add End
          } // lineRow != null
        } // for loop
      } // fetchedRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectIter != null)
      {
        selectIter.closeRowSetIterator();
      }
    }
  } // setIncludesTaxFlag()
// ver 1.2 Add End 

  // **************************************************************
  // 確認画面で使用するメソッド
  // **************************************************************

  /**
   * 職責レベルプロファイルを取得する
   * @return String プロファイル・オプション値
   */
  public String getRespLevel()
  {
    // 初期化処理
    String methodName = "getRespLevel";
    startProcedure(getClass().getName(), methodName);
    
    OADBTransaction transaction = getOADBTransaction();
    transaction.changeResponsibility(transaction.getResponsibilityId(),
      transaction.getResponsibilityApplicationId());
    String profileOption = transaction.getProfile("XX03_SLIP_AUTHORITIES");

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return profileOption;
  }

  // Ver11.5.10.1.6D Add Start
  /**
   * 職責レベルプロファイル(経理承認モジュール)を取得する
   * @return String プロファイル・オプション値
   */
  public String getAccAppMod()
  {
    OADBTransaction transaction = getOADBTransaction();
    transaction.changeResponsibility( transaction.getResponsibilityId()
                                     ,transaction.getResponsibilityApplicationId());
    String profileOption = transaction.getProfile("XX03_SLIP_ACC_APPROVE_MODULE");
    if ((profileOption == null) || "".equals(profileOption))
    {
      profileOption = "ALL";
    }

    return profileOption;
  }
  // Ver11.5.10.1.6D Add End
  
  /**
   * 承認階層クラスを取得する
   * @param receivableId 索引番号
   * @param executeQuery 
   * @return String 承認階層クラス値
   */
  public String getRecognitionClass(Number receivableId, Boolean executeQuery)
  {
    // 初期化処理
    String methodName = "getRecognitionClass";
    startProcedure(getClass().getName(), methodName);
    
    String retValue = null;
    Number recognitionClass;
    if (receivableId != null)
    {
    
      // 確定している支払伝票ヘッダを取得する
      Xx03ReceivableSlipsVOImpl hVo = getXx03ReceivableSlipsVO1();
      hVo.initQuery(receivableId, executeQuery);
      hVo.first();
      Xx03ReceivableSlipsVORowImpl row =
        (Xx03ReceivableSlipsVORowImpl)hVo.getCurrentRow();
      recognitionClass = row.getRecognitionClass();
      if(recognitionClass != null)
      {
        retValue = recognitionClass.toString();
      }
    }
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return retValue;
  }

  /**
   *
   * 経理修正フラグのON
   */
  public void setAccountRevision()
  {
    // 初期化処理
    String methodName = "setAccountRevision";
    startProcedure(getClass().getName(), methodName);

    // ビュー・オブジェクトの取得
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerVo.first();
    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

    headerRow.setAccountRevisionFlag(Xx03ArCommonUtil.STR_YES);

    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // setAccountRevision

  /**
   *
   * 経理修正一時フラグのON
   */
  public void setAccountRevisionTemp()
  {
    // 初期化処理
    String methodName = "setAccountRevision";
    startProcedure(getClass().getName(), methodName);

    // ビュー・オブジェクトの取得
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerVo.first();
    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

    headerRow.setAccountRevisionFlag("T");

    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // setAccountRevision

  /**
   * 一見顧客区分取得
   * @param なし
   * @return 一見顧客区分
   */
  public String getFirstCustomerFlag()
  {
    // 初期化処理
    String methodName = "getFirstCustomerFlag";
    startProcedure(getClass().getName(), methodName);
    String returnStr = "N";

    // ビュー・オブジェクトの取得
    OAViewObject headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.first();

    if (headerRow != null)
    {
      returnStr = headerRow.getFirstCustomerFlag(); 
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return returnStr;
  } // getFirstCustomerFlag

  /**
   * 伝票コピー
   */
  public Number copy()
  {
    // 初期化処理
    String methodName = "copy";
    startProcedure(getClass().getName(), methodName);

    // 変数    
    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;    
    int fetchedHeaderRowCount;
    int fetchedLineRowCount;
    Xx03ReceivableSlipsVORowImpl headerRow = null;
    Xx03ReceivableSlipsLineVORowImpl lineRow = null;
    Xx03ReceivableSlipsVORowImpl newHeaderRow = null;
    Row newLineRow = null;
    Number returnReceivableId = null;

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ReceivableSlipsVO1();      
      OAViewObject lineVo = getXx03ReceivableSlipsLineVO1();

      //Ver11.5.10.1.4D 2005/08/10 Modify Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      //fetchedLineRowCount = lineVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      fetchedLineRowCount = lineVo.getRowCount();
      //Ver11.5.10.1.4D 2005/08/10 Modify End
      
      Row[] tempLineRow = new Row[fetchedLineRowCount];
      
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");
      selectLineIter = lineVo.createRowSetIterator("selectLineIter");

      if ((fetchedHeaderRowCount != 1)
        && (fetchedLineRowCount <= 0))
      {
        // システムエラー
        throw new OAException("XX03",
                              "APP-XX03-13008",
                              null,
                              OAException.ERROR,
                              null);          
      }
          
      // ヘッダーのコピー
      headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
      if (headerRow != null)
      {
        // この方法では、linedrRowがnullとなる。
        newHeaderRow = (Xx03ReceivableSlipsVORowImpl)headerVo.createRow();
        copyHeaderRow(headerRow, newHeaderRow);

        // 明細のコピー
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(fetchedLineRowCount);

        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            tempLineRow[i] = lineVo.createAndInitRow(lineRow);
            tempLineRow[i].setAttribute("LineNumber", new Number(i+1));
          }
        } // for loop

        // 元のheaderRowのクリア
        headerRow.removeFromCollection();
        // headerRow.revert();
        headerVo.insertRow(newHeaderRow);

        // 明細コピー
        for (int i=0; i<fetchedLineRowCount; i++)
        {
          lineVo.next();

          //Ver11.5.10.1.6M Change Start
          try
          {
            newLineRow = lineVo.createRow();
            copyLineRow(tempLineRow[i], newLineRow);
            lineVo.insertRow(newLineRow);
          }
          catch(Exception e) 
          {
            newLineRow.remove();
            throw OAException.wrapperException(e);
          }
          //Ver11.5.10.1.6M Change End

          tempLineRow[i].remove();
        }

        returnReceivableId = newHeaderRow.getReceivableId();
      }
    } // try
    catch(Exception ex)
    {
      // debug
      ex.printStackTrace();
      // システムエラー
      throw new OAException("XX03",
                            "APP-XX03-13008",
                            null,
                            OAException.ERROR,
                            null);             
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();   
      }
    }
 
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return returnReceivableId;

  } // copy()

  /**
   * ヘッダー・コピー
   */
  public void copyHeaderRow(Row fromRow, 
                            Row toRow)
  {
    // 初期化処理
    String methodName = "copyHeaderRow";
    startProcedure(getClass().getName(), methodName);

    for (int i=0; i<Xx03ArCommonUtil.COPY_COL_HEADER.length; i++)
    {
      String attrName = Xx03ArCommonUtil.COPY_COL_HEADER[i];

      Object attrVal = fromRow.getAttribute(attrName);

      if (attrVal != null)
      {
        toRow.setAttribute(attrName ,attrVal);          
      }
    }
    //2005.04.15 add start Ver11.5.10.1      
    Object prepay = fromRow.getAttribute("CommitmentDateFrom");
    if(prepay != null)
    {
      // 前受金の有効日をコピー
      // 有効日(自)はシステム日付、有効日(至)はブランクとする
      OADBTransaction txn = getOADBTransaction();
      Date sysDate = new Date(txn.getCurrentDBDate().dateValue());
      // 有効日(自)
      if(sysDate != null)
      {
        toRow.setAttribute("CommitmentDateFrom" ,sysDate);
      }              
    }      
    //2005.04.15 add end Ver11.5.10.1

    // 終了処理
    endProcedure(getClass().getName(), methodName);

  } // copyHeaderRow

  /**
   * 明細コピー
   */
  public void copyLineRow(Row fromRow, 
                            Row toRow)
  {
    // 初期化処理
    String methodName = "copyLineRow";
    startProcedure(getClass().getName(), methodName);  

    for (int i=0; i<Xx03ArCommonUtil.COPY_COL_LINE.length; i++)
    {
      String attrName = Xx03ArCommonUtil.COPY_COL_LINE[i];

      Object attrVal = fromRow.getAttribute(attrName);

      if (attrVal != null)
      {
        toRow.setAttribute(attrName ,attrVal);          
      }
    }
    
    // 終了処理
    endProcedure(getClass().getName(), methodName);

  } // copyLineRow

  /**
   * 取消取引タイプ情報取得
   * @param transTypeId 取引タイプID
   * @return 取消取引タイプ情報
   */
  public Hashtable getCreditMemoTypeInfo(Number transTypeId)
  {
    // 初期化処理
    String methodName = "getCreditMemoTypeInfo";
    startProcedure(getClass().getName(), methodName);
    Hashtable returnHashTable = new Hashtable();

    // ビュー・オブジェクトの取得
    Xx03GetCreditTransTypeInfoVOImpl creditVo = getXx03GetCreditTransTypeInfoVO1();
    creditVo.initQuery(transTypeId);
    Xx03GetCreditTransTypeInfoVORowImpl creditRow = (Xx03GetCreditTransTypeInfoVORowImpl)creditVo.first();
    if (creditRow != null)
    {
      // クレジット・メモタイプ情報取得
      returnHashTable.put("creditTypeId", creditRow.getCustTrxTypeId());
      returnHashTable.put("creditTypeName", creditRow.getName());
    }
    else
    {
      // クレジット・メモタイプ定義なし
      throw new OAException("XX03",
                            "APP-XX03-14062",
                            null,
                            OAException.ERROR,
                            null);
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return returnHashTable;
  } // getCreditMemoTypeInfo

  // **************************************************************
  // PL/SQLパッケージの関数を使用するメソッド
  // **************************************************************

  /**
   * 支払予定日算出関数の呼出
   * @param termsId 支払条件ID
   * @param invoice 請求書日付
   * @return Date 支払予定日
   */
  public Date calcDueDate(Number termsId, Date invoiceDate)  {
    OADBTransaction txn = getOADBTransaction();
    Date dueDate = null; // 戻り値
    MessageToken msg= null;
    OAException excep = null;
    
    // 実行SQLブロック
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_DEPTINPUT_AR_CHECK_PKG.GET_TERMS_DATE" + 
        "(:1, :2, :3, :4, :5, :6); end;", 0);

    try
    {
      state.setLong(1, termsId.longValue());
      state.setDate(2, (java.sql.Date)invoiceDate.dateValue());
      state.registerOutParameter(3, Types.DATE);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);

      state.execute();

      dueDate = new Date(state.getDate(3));
      String retCode = state.getString(5);
      String errBuf = state.getString(4);
      
      state.close();

      // 正常終了
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return dueDate;
      }
      // エラー
      else
      {
        return null;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }
    }
  } // calcDueDate()

  /**
   * 仕訳チェック関数の呼出
   * @param receivableId 索引番号
   * @return Vector エラー・メッセージ
   */
  public Vector callDeptInputAr(Number receivableId)  {
    // 初期化処理
    String methodName = "callDeptInputAr";
    startProcedure(getClass().getName(), methodName);

    Vector exceptions = new Vector(); // 戻り値
    CallableStatement state = null;

    try
    {
      OADBTransaction txn = getOADBTransaction();
      MessageToken token = null;
      OAException msg = null;

      // 実行SQLブロック
      state = txn.createCallableStatement(
        //ver11.5.10.1.6O Chg Start
        //"begin XX03_DEPTINPUT_AR_CHECK_PKG.CHECK_DEPTINPUT_AR" + 
        "begin XX03_DEPTINPUT_AR_CHECK_PKG.CHECK_DEPTINPUT_AR_INPUT" + 
        //ver11.5.10.1.6O Chg End
        "(:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, " +
        ":14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, " +
        ":26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, " +
        ":38, :39, :40, :41, :42, :43, :44, :45, :46); end;", 0);

      state.setLong(1, receivableId.longValue());
      state.registerOutParameter(2, Types.INTEGER);
      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);
      state.registerOutParameter(7, Types.VARCHAR);
      state.registerOutParameter(8, Types.VARCHAR);
      state.registerOutParameter(9, Types.VARCHAR);
      state.registerOutParameter(10, Types.VARCHAR);
      state.registerOutParameter(11, Types.VARCHAR);
      state.registerOutParameter(12, Types.VARCHAR);
      state.registerOutParameter(13, Types.VARCHAR);
      state.registerOutParameter(14, Types.VARCHAR);
      state.registerOutParameter(15, Types.VARCHAR);
      state.registerOutParameter(16, Types.VARCHAR);
      state.registerOutParameter(17, Types.VARCHAR);
      state.registerOutParameter(18, Types.VARCHAR);
      state.registerOutParameter(19, Types.VARCHAR);
      state.registerOutParameter(20, Types.VARCHAR);
      state.registerOutParameter(21, Types.VARCHAR);
      state.registerOutParameter(22, Types.VARCHAR);
      state.registerOutParameter(23, Types.VARCHAR);
      state.registerOutParameter(24, Types.VARCHAR);
      state.registerOutParameter(25, Types.VARCHAR);
      state.registerOutParameter(26, Types.VARCHAR);
      state.registerOutParameter(27, Types.VARCHAR);
      state.registerOutParameter(28, Types.VARCHAR);
      state.registerOutParameter(29, Types.VARCHAR);
      state.registerOutParameter(30, Types.VARCHAR);
      state.registerOutParameter(31, Types.VARCHAR);
      state.registerOutParameter(32, Types.VARCHAR);
      state.registerOutParameter(33, Types.VARCHAR);
      state.registerOutParameter(34, Types.VARCHAR);
      state.registerOutParameter(35, Types.VARCHAR);
      state.registerOutParameter(36, Types.VARCHAR);
      state.registerOutParameter(37, Types.VARCHAR);
      state.registerOutParameter(38, Types.VARCHAR);
      state.registerOutParameter(39, Types.VARCHAR);
      state.registerOutParameter(40, Types.VARCHAR);
      state.registerOutParameter(41, Types.VARCHAR);
      state.registerOutParameter(42, Types.VARCHAR);
      state.registerOutParameter(43, Types.VARCHAR);
      state.registerOutParameter(44, Types.VARCHAR);
      state.registerOutParameter(45, Types.VARCHAR);
      state.registerOutParameter(46, Types.VARCHAR);

      state.execute();

      String errFlag = state.getString(3);
      int errCnt = new Integer(state.getString(2)).intValue();

      exceptions.addElement(errFlag);

      // 正常終了以外
      if (!Xx03ArCommonUtil.RETCODE_SUCCESS.equals(errFlag))
      {
        int indexNum = 0;
        byte messageType = OAException.ERROR;
        for (int i = 1; i <= errCnt; i++)
        {
          // エラー・メッセージは、5つ目の引数から開始
          indexNum = (3 + i * 2);
          token = new MessageToken("TOK_XX03_CHECK_ERROR",
                                   state.getString(indexNum));
          // 警告
          if (Xx03ArCommonUtil.RETCODE_WARNING.equals(errFlag))
          {
            messageType = OAException.WARNING;
          }

          msg = new OAException("XX03",
                                "APP-XX03-14101",
                                new MessageToken[]{token},
                                messageType,
                                null);

          exceptions.addElement(msg);

          token = null;
          msg   = null;
          
          //Ver11.5.10.1.6H 2005/12/28 Add Start
          // エラー件数が20件を超えた場合、エラーメッセージ表示は終了する
          if (20 <= i)
          {
            i = errCnt + 1;
          }
          //Ver11.5.10.1.6H 2005/12/28 Add End
          
        }
      }
    }
    catch(SQLException ex)
    {
      throw new OAException(ex.getMessage());
    }
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }
    finally
    {
      try{
        state.close();
      }
      catch(SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return exceptions;
  } // callDeptInputAr

  /**
   * ワークフロー関数の呼出(申請)
   * @param
   * @return 伝票番号
   */
  public String startDivProcess()
  {
    // 初期化処理
    String methodName = "startDivProcess";
    startProcedure(getClass().getName(), methodName);

    String errMsg = null;
    Hashtable returnHashtable = null;
    String retReceivableNum = null;
    
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;

    //ver11.5.10.1.6 Add Start
    RowSetIterator selectUpdIter = null;
    int fetchedUpdRowCount;
    //ver11.5.10.1.6 Add End

    try
    {
      // ビュー・オブジェクトの取得
      //ver11.5.10.1.6 Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      //ver11.5.10.1.6 Chg Start

      if (headerVo == null)
      {
        // エラー・メッセージ
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
        //ver11.5.10.1.6 Chg End
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }

      //ver11.5.10.1.6 Add Start
      OAViewObject updVo = getXx03ConfirmUpdSlipsVO1();
      if (updVo == null)
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13035", tokens);
      }
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //Xx03ReceivableSlipsVORowImpl headerRow = null;
      Xx03ConfirmDispSlipsVORowImpl headerRow = null;
      Xx03ConfirmUpdSlipsVORowImpl  updRow    = null;
      //ver11.5.10.1.6 Chg End
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter      = headerVo.createRowSetIterator("selectHeaderIter");

      //ver11.5.10.1.6 Add Start
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedUpdRowCount    = updVo.getFetchedRowCount();
      fetchedUpdRowCount    = updVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectUpdIter         = updVo.createRowSetIterator("selectUpdIter");
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedHeaderRowCount > 0)
      if ((fetchedHeaderRowCount > 0) && (fetchedUpdRowCount > 0))
      //ver11.5.10.1.6 Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        //ver11.5.10.1.6 Chg Start
        //headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();
        updRow    = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        //ver11.5.10.1.6 Chg End
        {
          //ver11.5.10.1.6 Chg Start
          //returnHashtable = startDivProcess(headerRow.getReceivableId(),
          //                                   headerRow.getRequestorPersonId(),
          //                                   headerRow.getApproverPersonId());
          returnHashtable = startDivProcess( headerRow.getReceivableId()
                                            ,headerRow.getRequestorPersonId()
                                            ,updRow.getApproverPersonId());
          //ver11.5.10.1.6 Chg End

          errMsg = (String)returnHashtable.get("result");
          retReceivableNum = (String)returnHashtable.get("receivableNum");

          if (!(Xx03ArCommonUtil.SUCCESS.equals(errMsg)))
          {
            throw new OAException(errMsg);
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        //throw new OAException("XX03", "APP-XX03-13034", tokens);
        if (fetchedHeaderRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        if (fetchedUpdRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        //ver11.5.10.1.6 Chg End
      } // fetchedHeaderRowCount

      // 終了処理
      endProcedure(getClass().getName(), methodName);  
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6 Add Start
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6 Add End
    }
    return retReceivableNum;
  } // startDivProcess

  /**
   * ワークフロー関数の呼出(申請)
   * @param receivableId 索引番号
   * @return String メッセージ
   */
  public Hashtable startDivProcess(Number receivableId,
                                Number requestorPersonId,
                                Number approverPersonId)
  {
    OADBTransaction txn = getOADBTransaction();
    Hashtable returnHashTable = new Hashtable();

    // 実行SQLブロック
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.START_DIV_PROCESS" + 
        "(:1, :2, :3, :4, :5, :6, :7); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setLong(2, requestorPersonId.longValue());
      state.setLong(3, approverPersonId.longValue());      
      state.registerOutParameter(4, Types.VARCHAR);    
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);
      state.registerOutParameter(7, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(6);
      String errBuf = state.getString(5);
      String receivableNum = state.getString(4);
      
      state.close();

      // エラーなし
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        // 戻り値セット
        returnHashTable.put("result", Xx03ArCommonUtil.SUCCESS);
        returnHashTable.put("receivableNum", receivableNum);
        return returnHashTable;
      }
      // エラーなし、警告あり
      else
      {
        returnHashTable.put("result", errBuf);
        returnHashTable.put("receivableNum", "");
        return returnHashTable;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());      
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }      
    }
  } // startDivProcess

  /**
   * ワークフロー関数の呼出(部門承認/部門否認)
   * @param receivableId 伝票ID
   * @param requestKey 申請キー(ItemKey)
   * @param approverPersonId 承認者ID
   * @param answerFlag 承認結果フラグ(Y/N)
   * @param approverComments 承認者コメント
   * @param nextApproverPersonId 次の承認者の従業員ID
   * @return String メッセージ
   */
  public String answerDivProposal(Number receivableId,
                                 String requestKey,
                                 Number approverPersonId,
                                 String answerFlag,
                                 String approverComments,
                                 Number nextApproverPersonId)
  {
    OADBTransaction txn = getOADBTransaction();

    // 実行SQLブロック
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.ANSWER_DIV_PROPOSAL" + 
        "(:1, :2, :3, :4, :5, :6, :7, :8, :9); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setString(2, requestKey);
      state.setLong(3, approverPersonId.longValue());
      state.setString(4, answerFlag);

      if (approverComments != null)
      {
        state.setString(5, approverComments);            
      }
      else
      {
        state.setNull(5, Types.VARCHAR);
      }

      if (approverPersonId.compareTo(nextApproverPersonId) != 0)
      {
        state.setLong(6, nextApproverPersonId.longValue());        
      }
      else
      {
        state.setNull(6, Types.INTEGER);        
      }

      state.registerOutParameter(7, Types.VARCHAR);
      state.registerOutParameter(8, Types.VARCHAR);
      state.registerOutParameter(9, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(8);
      String errBuf = state.getString(7);

      state.close();

      // 正常終了
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return Xx03ArCommonUtil.SUCCESS;
      }
      // エラー
      else
      {
        return errBuf;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());      
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }      
    }
  } // answerDivProcess

  /**
   * ワークフロー関数の呼出(経理承認/経理否認)
   * @param answerFlag  回答フラグ
   * @param answerId    回答者ID
   * @return
   */
  public void startAccProcess(String answerFlag, Number answerId)
  {
    // 初期化処理
    String methodName = "startAccProcess";
    startProcedure(getClass().getName(), methodName);

    String errMsg = null;
    
    RowSetIterator selectHeaderIter = null;    
    int fetchedHeaderRowCount;
    //ver11.5.10.1.6 Add Start
    RowSetIterator selectUpdIter = null;
    int fetchedUpdRowCount;
    //ver11.5.10.1.6 Add End

    try
    {
      // ビュー・オブジェクトの取得
      //ver11.5.10.1.6 Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //Xx03ReceivableSlipsVORowImpl headerRow = null;
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      Xx03ConfirmDispSlipsVORowImpl headerRow = null;
      OAViewObject updVo = getXx03ConfirmUpdSlipsVO1();
      Xx03ConfirmUpdSlipsVORowImpl updRow = null;
      //ver11.5.10.1.6 Chg End

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      //ver11.5.10.1.6 Add Start
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedUpdRowCount = updVo.getFetchedRowCount();
      fetchedUpdRowCount = updVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectUpdIter = updVo.createRowSetIterator("selectUpdIter");
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedHeaderRowCount > 0)
      if ((fetchedHeaderRowCount > 0) && (fetchedUpdRowCount > 0))
      //ver11.5.10.1.6 Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        //ver11.5.10.1.6 Add Start
        selectUpdIter.setRangeStart(0);
        selectUpdIter.setRangeSize(fetchedUpdRowCount);
        //ver11.5.10.1.6 Add End

        //ver11.5.10.1.6 Chg Start
        //headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();
        updRow    = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        //ver11.5.10.1.6 Chg End
        {
          //ver11.5.10.1.6 Chg Start
          //errMsg = startAccProcess(headerRow.getReceivableId(),
          //                         answerId,
          //                         answerFlag,
          //                         headerRow.getApproverComments());
          errMsg = startAccProcess( headerRow.getReceivableId()
                                   ,answerId
                                   ,answerFlag
                                   ,updRow.getApproverComments());
          //ver11.5.10.1.6 Chg End

          if (!(Xx03ArCommonUtil.SUCCESS.equals(errMsg)))
          {
            throw new OAException(errMsg);
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        //throw new OAException("XX03", "APP-XX03-13034", tokens);
        if (fetchedHeaderRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        if (fetchedUpdRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        //ver11.5.10.1.6 Chg End
      } // fetchedHeaderRowCount

      // 終了処理
      endProcedure(getClass().getName(), methodName);  
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6O Add Start
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6O Add End
    }
  } // startAccProcess

  /**
   * ワークフロー関数の呼出(経理承認)
   * @param receivableId 索引番号
   * @param approverPersonId 承認者ID
   * @param answerFlag 承認時'Y'／却下時'N'
   * @param approverComments コメント
   * @return String メッセージ
   */
  public String startAccProcess(Number receivableId,
                                Number approverPersonId,
                                String answerFlag,
                                String approverComments)
  {
    OADBTransaction txn = getOADBTransaction();

    // 実行SQLブロック
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.START_ACC_PROCESS" + 
        "(:1, :2, :3, :4, :5, :6, :7); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setLong(2, approverPersonId.longValue());
      state.setString(3, answerFlag);
      if (approverComments != null)
      {
       state.setString(4, approverComments);            
      }
      else
      {
        state.setNull(4, Types.VARCHAR);
      }
      state.registerOutParameter(5, Types.VARCHAR);
      state.registerOutParameter(6, Types.VARCHAR);
      state.registerOutParameter(7, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(6);
      String errBuf = state.getString(5);

      state.close();

      // 正常終了
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return Xx03ArCommonUtil.SUCCESS;
      }
      // エラー
      else
      {
        return errBuf;
      }
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());      
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);    
      }      
    }
  } // startAccProcess

  /**
   * ワークフロー関数の呼出(申請取消)
   * @param answerFlag
   * @return
   */
  public void cancelProposal()
  {
    // 初期化処理
    String methodName = "cancelProposal";
    startProcedure(getClass().getName(), methodName);

    String errMsg = null;
    
    RowSetIterator selectHeaderIter = null;
    int fetchedHeaderRowCount;

    //ver11.5.10.1.6 Add Start
    RowSetIterator selectUpdIter = null;
    int fetchedUpdRowCount;
    //ver11.5.10.1.6 Add End

    try
    {
      // ビュー・オブジェクトの取得
      //ver11.5.10.1.6 Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //Xx03ReceivableSlipsVORowImpl headerRow = null;
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      Xx03ConfirmDispSlipsVORowImpl headerRow = null;
      //ver11.5.10.1.6 Chg End

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      //ver11.5.10.1.6 Add Start
      OAViewObject updVo = getXx03ConfirmUpdSlipsVO1();
      Xx03ConfirmUpdSlipsVORowImpl updRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedUpdRowCount = updVo.getFetchedRowCount();
      fetchedUpdRowCount = updVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectUpdIter = updVo.createRowSetIterator("selectUpdIter");
      //ver11.5.10.1.6 Add End

      //ver11.5.10.1.6 Chg Start
      //if (fetchedHeaderRowCount > 0)
      if ((fetchedHeaderRowCount > 0) && (fetchedUpdRowCount > 0))
      //ver11.5.10.1.6 Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);
        //ver11.5.10.1.6 Add Start
        selectUpdIter.setRangeStart(0);
        selectUpdIter.setRangeSize(fetchedUpdRowCount);
        //ver11.5.10.1.6 Add End

        //ver11.5.10.1.6 Chg Start
        //headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();
        updRow    = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver11.5.10.1.6 Chg End

        //ver11.5.10.1.6 Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        //ver11.5.10.1.6 Chg End
        {
          errMsg = cancelProposal(headerRow.getReceivableId(),
                                  headerRow.getRequestKey());
         
          if (!(Xx03ArCommonUtil.SUCCESS.equals(errMsg)))
          {
            throw new OAException(errMsg);
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        //ver11.5.10.1.6 Chg Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        //throw new OAException("XX03", "APP-XX03-13034", tokens);
        if (fetchedHeaderRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        if (fetchedUpdRowCount > 0)
        {
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        }
        //ver11.5.10.1.6 Chg End
      } // fetchedHeaderRowCount

      // 終了処理
      endProcedure(getClass().getName(), methodName);   
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();        
      }
      //ver11.5.10.1.6 Add Start
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      //ver11.5.10.1.6 Add End
    }   
  } // cancelProposal

  /**
   * ワークフロー関数の呼出(申請取消)
   * @param receivableId 索引番号
   * @param requestKey 申請キー（WorkFlow用）
   * @return String メッセージ
   */
  public String cancelProposal(Number receivableId,
                               String requestKey)
  {
    OADBTransaction txn = getOADBTransaction();

    // 実行SQLブロック
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_AR_ENTRY_WORKFLOW_PKG.CANCEL_PROPOSAL" + 
        "(:1, :2, :3, :4, :5); end;", 0);

    try
    {
      state.setLong(1, receivableId.longValue());
      state.setString(2, requestKey);

      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(4);
      String errBuf = state.getString(3);
      
      state.close();

      // 正常終了
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return Xx03ArCommonUtil.SUCCESS;
      }
      // エラー
      else
      {
        return errBuf;
      }
    }
    catch (SQLException sqlEx)
    {
      throw new OAException(sqlEx.getMessage());
    }
    catch (NumberFormatException numEx)
    {
      throw new NumberFormatException(numEx.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }
  } // cancelProposal

  /**
   * オルグ名称取得
   * @param なし
   * @return String オルグ名称
   */
  public String getOrgname()
  {
    // 2006/01/23 Ver11.5.10.1.6L Add Start
    OADBTransaction txn = getOADBTransaction();
    // 2006/01/23 Ver11.5.10.1.6L Add End

    // 実行SQLブロック
    CallableStatement state =
      txn.createCallableStatement(
        "begin XX03_BOOKS_ORG_NAME_GET_PKG.ORG_NAME" + 
        "(:1, :2, :3, :4, XX00_PROFILE_PKG.VALUE('ORG_ID')); end;", 0);

    try
    {
      state.registerOutParameter(1, Types.VARCHAR);
      state.registerOutParameter(2, Types.VARCHAR);
      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);

      state.execute();

      String retCode = state.getString(2);
      String errBuf = state.getString(1);
      String orgName = state.getString(4);
      
      state.close();

      // 正常終了
      if (Xx03ArCommonUtil.SUCCESS.equals(retCode))
      {
        return orgName;
      }
      // エラー
      else
      {
        // エラー・メッセージ
        // 2006/01/23 Ver11.5.10.1.6L Change Start
        //MessageToken[] tokens = {new MessageToken("OBJECT_NAME", Xx03ArCommonUtil.MESSAGE_STR_ORG_NAME_INFO)};
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", txn.getMessage("XX03","APP-XX03-34067",null))};
        throw new OAException("XX03","APP-XX03-13036", tokens);
        // 2006/01/23 Ver11.5.10.1.6L Change End
      }
    }
    catch (SQLException sqlEx)
    {
      throw new OAException(sqlEx.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }
  } // getOrgname

  // Ver1.4 change start ------------------------------------------------------
  /**
   * 前受金有効日チェック処理
   * @return なし
   */
  public void checkCommitmentDate()
  {
    String commitmentNumber = null;
    Date startDate = null;
    Date endDate = null;
    Date invoiceDate = null;

    // ビュー・オブジェクトの取得
    Xx03ReceivableSlipsVOImpl headerVo = getXx03ReceivableSlipsVO1();
    Xx03ReceivableSlipsVORowImpl headerRow = null;

    headerVo.first();
    headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

    // 前受充当伝票番号の取得
    commitmentNumber = headerRow.getCommitmentNumber();

    // 請求書日付の取得
    invoiceDate = headerRow.getInvoiceDate();

    // 前受充当伝票の有効日の取得
    // ビュー・オブジェクトの取得
    Xx03CommitmentDateVOImpl vo = getXx03CommitmentDateVO1();
    vo.initQuery(commitmentNumber);
    vo.first();

    Xx03CommitmentDateVORowImpl row = (Xx03CommitmentDateVORowImpl)vo.getCurrentRow();

    // 前受金の有効日取得
    startDate = row.getStartDateCommitment();
    endDate = row.getEndDateCommitment();

    if(endDate == null)
    {
      endDate = invoiceDate;
    }
  
   // 有効日チェック
    if (startDate != null)
    {
      // 前受金の時(有効日(自)が入力されている時)のみチェック
      if (endDate != null)
      {
        // 有効日(自)、有効日(至)両方が指定されている時
        if ((invoiceDate.compareTo(startDate) < 0)
            || (invoiceDate.compareTo(endDate) > 0))
          // 請求書日付 < 有効日(自) or 請求書日付 > 有効日(至)の時
          throw new OAException("XX03",
                                "APP-XX03-14065",
                                null,
                                OAException.ERROR,
                                null);
      }
      else
      {
        // 有効日(自)のみが指定されている時
        if (invoiceDate.compareTo(startDate) < 0)
        {
          // 請求書日付 < 有効日(自)の時
          throw new OAException("XX03",
                                "APP-XX03-14065",
                                null,
                                OAException.ERROR,
                                null);
        }
      }
    }
  } // checkCommitmentDate()

  /**
   * 支払方法有効日チェック処理
   * @return なし
   */
  //ver11.5.10.1.6 Del Start
  //public void checkPaymentDate()
  //{
  //  Date recStartDate = null;
  //  Date recEndDate = null;
  //  Date custStartDate = null;
  //  Date custEndDate = null;
  //  Date invoiceDate = null;

  //  // ビュー・オブジェクトの取得
  //  Xx03ReceivableSlipsVOImpl headerVo = getXx03ReceivableSlipsVO1();
  //  Xx03ReceivableSlipsVORowImpl headerRow = null;

  //  headerVo.first();
  //  headerRow = (Xx03ReceivableSlipsVORowImpl)headerVo.getCurrentRow();

  //  // 支払方法IDの取得
  //  Number receiptMethodId = headerRow.getReceiptMethodId();

  //  // 請求書日付の取得
  //  invoiceDate = headerRow.getInvoiceDate();

  //  // 支払方法の有効日の取得(支払方法のに紐付く有効日と顧客に紐付く有効日)
  //  // ビュー・オブジェクトの取得
  //  Xx03PaymentDateVOImpl vo = getXx03PaymentDateVO1();

  //  vo.initQuery(receiptMethodId);

  //  vo.first();

  //  Xx03PaymentDateVORowImpl row = (Xx03PaymentDateVORowImpl)vo.getCurrentRow();

  //  // 支払方法に紐付く有効日取得
  //  recStartDate = row.getRecStartDate();
  //  recEndDate = row.getRecEndDate();

  //  if(recEndDate == null)
  //  {
  //    recEndDate = invoiceDate;
  //  }
    
  //  // 支払方法に紐付く有効日チェック
  //  if (recStartDate != null)
  //  {
  //    // 支払方法の有効日(自)が入力されている時)のみチェック
  //    if (recEndDate != null)
  //    {
  //      // 有効日(自)、有効日(至)両方が指定されている時
  //      if ((invoiceDate.compareTo(recStartDate) < 0)
  //          || (invoiceDate.compareTo(recEndDate) > 0))
  //        // 請求書日付 < 有効日(自) or 請求書日付 > 有効日(至)の時
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //    }
  //    else
  //    {
  //      // 有効日(自)のみが指定されている時
  //      if (invoiceDate.compareTo(recStartDate) < 0)
  //      {
  //        // 請求書日付 < 有効日(自)の時
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //      }
  //    }
  //  }

  //  // 顧客に紐付く有効日取得
  //  custStartDate = row.getCustStartDate();
  //  custEndDate = row.getCustEndDate();

  //  if(custEndDate == null)
  //  {
  //    custEndDate = invoiceDate;
  //  }

  //  // 支払方法に紐付く有効日チェック
  //  if (custStartDate != null)
  //  {
  //    // 支払方法の有効日(自)が入力されている時)のみチェック
  //    if (custEndDate != null)
  //    {
  //      // 有効日(自)、有効日(至)両方が指定されている時
  //      if ((invoiceDate.compareTo(custStartDate) < 0)
  //          || (invoiceDate.compareTo(custEndDate) > 0))
  //        // 請求書日付 < 有効日(自) or 請求書日付 > 有効日(至)の時
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //    }
  //    else
  //    {
  //      // 有効日(自)のみが指定されている時
  //      if (invoiceDate.compareTo(custStartDate) < 0)
  //      {
  //        // 請求書日付 < 有効日(自)の時
  //        throw new OAException("XX03",
  //                              "APP-XX03-14066",
  //                              null,
  //                              OAException.ERROR,
  //                              null);
  //      }
  //    }
  //  }
    
  //} // checkPaymentDate()
  //ver11.5.10.1.6 Del End

// ver 1.3 Add Start 有効日チェック追加 ----------------------------------
//  /**
//   * 前受金有効日チェック処理
//   * @param startDateCommitment 有効日(自)
//   * @param endDateCommitment 有効日(至)
//   * @param invoiceDate 請求書日付
//   * @return なし
//   */
//  public void checkCommitmentDate(Date startDateCommitment, Date endDateCommitment,
//    Date invoiceDate)
//  {
//    if (startDateCommitment != null)
//    {
//      // 前受金の時(有効日(自)が入力されている時)のみチェック
//      if (endDateCommitment != null)
//      {
//        // 有効日(自)、有効日(至)両方が指定されている時
//        if ((invoiceDate.compareTo(startDateCommitment) < 0)
//            || (invoiceDate.compareTo(endDateCommitment) > 0))
//          // 請求書日付 < 有効日(自) or 請求書日付 > 有効日(至)の時
//          throw new OAException("XX03",
//                                "APP-XX03-14065",
//                                null,
//                                OAException.ERROR,
//                                null);
//      }
//      else
//      {
//        // 有効日(自)のみが指定されている時
//        if (invoiceDate.compareTo(startDateCommitment) < 0)
//        {
//          // 請求書日付 < 有効日(自)の時
//          throw new OAException("XX03",
//                                "APP-XX03-14065",
//                                null,
//                                OAException.ERROR,
//                                null);
//        }
//      }
//    }
//  } // checkCommitmentDate()
//
//  /**
//   * 支払方法有効日チェック処理
//   * @param startDatePayment 有効日(自)
//   * @param endDatePayment 有効日(至)
//   * @param invoiceDate 請求書日付
//   * @return なし
//   */
//  public void checkPaymentDate(Date startDatePayment, Date endDatePayment,
//    Date invoiceDate)
//  {
//    if (startDatePayment != null)
//    {
//      // 支払方法の有効日(自)が入力されている時)のみチェック
//      if (endDatePayment != null)
//      {
//        // 有効日(自)、有効日(至)両方が指定されている時
//        if ((invoiceDate.compareTo(startDatePayment) < 0)
//            || (invoiceDate.compareTo(endDatePayment) > 0))
//          // 請求書日付 < 有効日(自) or 請求書日付 > 有効日(至)の時
//          throw new OAException("XX03",
//                                "APP-XX03-14066",
//                                null,
//                                OAException.ERROR,
//                                null);
//      }
//      else
//      {
//        // 有効日(自)のみが指定されている時
//        if (invoiceDate.compareTo(startDatePayment) < 0)
//        {
//          // 請求書日付 < 有効日(自)の時
//          throw new OAException("XX03",
//                                "APP-XX03-14066",
//                                null,
//                                OAException.ERROR,
//                                null);
//        }
//      }
//    }
//  } // checkPaymentDate()
// ver 1.3 Add End ----------------------------------------------------------
// Ver1.4 change end --------------------------------------------------------


  /**
   * 初期処理
   * @param moduleName モジュール名
   * @return procedureName プロシージャ名
   */
  public void startProcedure(String moduleName, String procedureName)
  {
    OADBTransaction txn = (OADBTransaction)getTransaction();
    if (txn.isLoggingEnabled())
    {
      txn.startTimedProcedure(moduleName, procedureName);    
    }
    // debug
    //    System.out.println("start " + moduleName + "." + procedureName);
  } // startProcedure() 

  /**
   * 終了処理
   * @param moduleName モジュール名
   * @return procedureName プロシージャ名
   */
  public void endProcedure(String moduleName, String procedureName)
  {
    OADBTransaction txn = (OADBTransaction)getTransaction();
    if (txn.isLoggingEnabled())
    {
      txn.endTimedProcedure(moduleName, procedureName);
    }
    // debug
    //    System.out.println("end   " + moduleName + "." + procedureName);    
  } // endProcedure() 




  /**
   * 
   * Container's getter for Xx03TaxCodesLovVO1
   */
  public Xx03TaxCodesLovVOImpl getXx03TaxCodesLovVO1()
  {
    return (Xx03TaxCodesLovVOImpl)findViewObject("Xx03TaxCodesLovVO1");
  }

  /**
   * 
   * Container's getter for Xx03PrecisionVO1
   */
  public Xx03PrecisionVOImpl getXx03PrecisionVO1()
  {
    return (Xx03PrecisionVOImpl)findViewObject("Xx03PrecisionVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsVO1
   */
  public Xx03ReceivableSlipsVOImpl getXx03ReceivableSlipsVO1()
  {
    return (Xx03ReceivableSlipsVOImpl)findViewObject("Xx03ReceivableSlipsVO1");
  }


  /**
   * 
   * Container's getter for Xx03ArInvoiceInputSlipPVO1
   */
  public Xx03ArInvoiceInputSlipPVOImpl getXx03ArInvoiceInputSlipPVO1()
  {
    return (Xx03ArInvoiceInputSlipPVOImpl)findViewObject("Xx03ArInvoiceInputSlipPVO1");
  }



  /**
   * 
   * Container's getter for Xx03PrePayButtonVO1
   */
  public Xx03PrePayButtonVOImpl getXx03PrePayButtonVO1()
  {
    return (Xx03PrePayButtonVOImpl)findViewObject("Xx03PrePayButtonVO1");
  }

  /**
   * 
   * Container's getter for Xx03SlipNumbersVO1
   */
  public Xx03SlipNumbersVOImpl getXx03SlipNumbersVO1()
  {
    return (Xx03SlipNumbersVOImpl)findViewObject("Xx03SlipNumbersVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetAutoAccountInfoMemoVO1
   */
  public Xx03GetAutoAccountInfoMemoVOImpl getXx03GetAutoAccountInfoMemoVO1()
  {
    return (Xx03GetAutoAccountInfoMemoVOImpl)findViewObject("Xx03GetAutoAccountInfoMemoVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetAutoAccountInfoCustomerVO1
   */
  public Xx03GetAutoAccountInfoCustomerVOImpl getXx03GetAutoAccountInfoCustomerVO1()
  {
    return (Xx03GetAutoAccountInfoCustomerVOImpl)findViewObject("Xx03GetAutoAccountInfoCustomerVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetTaxOverrideVO1
   */
  public Xx03GetTaxOverrideVOImpl getXx03GetTaxOverrideVO1()
  {
    return (Xx03GetTaxOverrideVOImpl)findViewObject("Xx03GetTaxOverrideVO1");
  }

  /**
   * 
   * Container's getter for Xx03CustTaxOptionVO1
   */
  public Xx03CustTaxOptionVOImpl getXx03CustTaxOptionVO1()
  {
    return (Xx03CustTaxOptionVOImpl)findViewObject("Xx03CustTaxOptionVO1");
  }

  /**
   * 
   * Container's getter for Xx03SystemTaxOptionVO1
   */
  public Xx03SystemTaxOptionVOImpl getXx03SystemTaxOptionVO1()
  {
    return (Xx03SystemTaxOptionVOImpl)findViewObject("Xx03SystemTaxOptionVO1");
  }


  /**
   * 
   * Container's getter for Xx03CheckCommitmentNumberVO1
   */
  public Xx03CheckCommitmentNumberVOImpl getXx03CheckCommitmentNumberVO1()
  {
    return (Xx03CheckCommitmentNumberVOImpl)findViewObject("Xx03CheckCommitmentNumberVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsLineVO1
   */
  public Xx03ReceivableSlipsLineVOImpl getXx03ReceivableSlipsLineVO1()
  {
    return (Xx03ReceivableSlipsLineVOImpl)findViewObject("Xx03ReceivableSlipsLineVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsToLinesVL1
   */
  public ViewLinkImpl getXx03ReceivableSlipsToLinesVL1()
  {
    return (ViewLinkImpl)findViewLink("Xx03ReceivableSlipsToLinesVL1");
  }

  /**
   * 
   * Container's getter for Xx03GetCreditTransTypeInfoVO1
   */
  public Xx03GetCreditTransTypeInfoVOImpl getXx03GetCreditTransTypeInfoVO1()
  {
    return (Xx03GetCreditTransTypeInfoVOImpl)findViewObject("Xx03GetCreditTransTypeInfoVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetBaseCurrencyVO1
   */
  public Xx03GetBaseCurrencyVOImpl getXx03GetBaseCurrencyVO1()
  {
    return (Xx03GetBaseCurrencyVOImpl)findViewObject("Xx03GetBaseCurrencyVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetAffPromptVO1
   */
  public Xx03GetAffPromptVOImpl getXx03GetAffPromptVO1()
  {
    return (Xx03GetAffPromptVOImpl)findViewObject("Xx03GetAffPromptVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetDffPromptVO1
   */
  public Xx03GetDffPromptVOImpl getXx03GetDffPromptVO1()
  {
    return (Xx03GetDffPromptVOImpl)findViewObject("Xx03GetDffPromptVO1");
  }

  /**
   * 
   * Container's getter for Xx03TaxClassLovVO1
   */
  public Xx03TaxClassLovVOImpl getXx03TaxClassLovVO1()
  {
    return (Xx03TaxClassLovVOImpl)findViewObject("Xx03TaxClassLovVO1");
  }

  // ver1.3 add start ---------------------------------------------------------
  /**
   * 
   * Container's getter for Xx03SelectedPrecisionVO1
   */
  public Xx03SelectedPrecisionVOImpl getXx03SelectedPrecisionVO1()
  {
    return (Xx03SelectedPrecisionVOImpl)findViewObject("Xx03SelectedPrecisionVO1");
  }
  // ver1.3 add end -----------------------------------------------------------

  // ver1.4 add start ---------------------------------------------------------
  /**
   * 
   * Container's getter for Xx03CommitmentDateVO1
   */
  public Xx03CommitmentDateVOImpl getXx03CommitmentDateVO1()
  {
    return (Xx03CommitmentDateVOImpl)findViewObject("Xx03CommitmentDateVO1");
  }

  // ver1.4 add end -----------------------------------------------------------

  // Ver11.5.10.1.4 2005/07/25 Add Start
  /**
   * 
   * 切上
   * 
   * @param   calNum    数値
   * @param   precision 精度
   */
//ver 11.5.10.2.10D Chg Start
//  private Number roundUp(Number calNum,
//                         double precision)
//  {
//    calNum = calNum.multiply(precision);
//    calNum = (Number)calNum.ceil();
//    calNum = calNum.divide(precision);
//
//    return calNum;
//  } // roundUp
  private Number roundUp(Number calNum,
                         Number precision)
  {
    Number numWk = null;
    numWk = new Number(calNum.abs());
    numWk = numWk.multiply(new Number(10).pow(precision));
    numWk = new Number(numWk.ceil());
    numWk = numWk.multiply(new Number(1).mod(10).pow(precision));
    numWk = numWk.multiply(new Number(calNum.sign()));
    return numWk;
  } // roundUp
//ver 11.5.10.2.10D Chg End

  /**
   * 
   * 切捨
   * 
   * @param   calNum    数値
   * @param   precision 精度
   */
//ver 11.5.10.2.10D Chg Start
//  private Number roundDown(Number calNum,
//                           double precision)
//  {
//    calNum = calNum.multiply(precision);
//    calNum = (Number)calNum.floor();
//    calNum = calNum.divide(precision);
//
//    return calNum;
//  } // roundDown  
  private Number roundDown(Number calNum,
                           Number precision)
  {
    Number numWk = null;
    numWk = new Number(calNum.truncate(precision.intValue()));
    return numWk;
  } // roundDown  
//ver 11.5.10.2.10D Chg End

  /**
   * 
   * 四捨五入
   * 
   * @param   calNum    数値
   * @param   precision 精度
   */
//ver 11.5.10.2.10D Chg Start
//  private Number round(Number calNum,
//                       int precision)
//  {
//    calNum = (Number)calNum.round(precision);
//    return calNum;
//  } // round
  private Number round(Number calNum,
                       Number precision)
  {
    Number numWk = null;
    numWk = new Number(calNum.round(precision.intValue()));
    return numWk;
  } // round
//ver 11.5.10.2.10D Chg End


  // Ver11.5.10.1.4 2005/07/25 add end

  /**
   * 
   * Container's getter for Xx03ConfirmDispSlipsVO1
   */
  public Xx03ConfirmDispSlipsVOImpl getXx03ConfirmDispSlipsVO1()
  {
    return (Xx03ConfirmDispSlipsVOImpl)findViewObject("Xx03ConfirmDispSlipsVO1");
  }

  /**
   * 
   * Container's getter for Xx03ConfirmDispSlipsLineVO1
   */
  public Xx03ConfirmDispSlipsLineVOImpl getXx03ConfirmDispSlipsLineVO1()
  {
    return (Xx03ConfirmDispSlipsLineVOImpl)findViewObject("Xx03ConfirmDispSlipsLineVO1");
  }

  /**
   * 
   * Container's getter for Xx03ConfirmUpdSlipsVO1
   */
  public Xx03ConfirmUpdSlipsVOImpl getXx03ConfirmUpdSlipsVO1()
  {
    return (Xx03ConfirmUpdSlipsVOImpl)findViewObject("Xx03ConfirmUpdSlipsVO1");
  }

  /**
   * 
   * Container's getter for Xx03ConfirmDispSlipsToLinesVL1
   */
  public ViewLinkImpl getXx03ConfirmDispSlipsToLinesVL1()
  {
    return (ViewLinkImpl)findViewLink("Xx03ConfirmDispSlipsToLinesVL1");
  }

  //ver11.5.10.1.6 Add Start
  /**
   * 請求伝票の検索（確認画面用）
   * @param receivableId 索引番号
   * @param executeQuery 
   * @return なし
   */
  public void initConfirmReceivableSlips(Number receivableId)
  {
    // 初期化処理
    String methodName = "initConfirmReceivableSlips";
    startProcedure(getClass().getName(), methodName);

    // 表示用ビュー・オブジェクトの取得
    Xx03ConfirmDispSlipsVOImpl dispVo = getXx03ConfirmDispSlipsVO1();
    dispVo.initQuery(receivableId);

    // 更新用ビュー・オブジェクトの取得
    Xx03ConfirmUpdSlipsVOImpl  updVo  = getXx03ConfirmUpdSlipsVO1();
    updVo.initQuery(receivableId);

    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // end initConfirmReceivableSlips()
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * 確認画面での伝票の保存
   * @param なし
   * @return なし
   */
  public void confirmSave()
  {
    // 初期化処理
    String methodName = "confirmSave";
    startProcedure(getClass().getName(), methodName);

    // ビュー・オブジェクトの取得
    int fetchedHeaderRowCount;
    RowSetIterator selectHeaderIter = null;
    OAViewObject headerVo = getXx03ConfirmUpdSlipsVO1();

    try
    {
      Xx03ConfirmUpdSlipsVORowImpl headerRow = null;
      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedHeaderRowCount = headerVo.getFetchedRowCount();
      fetchedHeaderRowCount = headerVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");

      if (fetchedHeaderRowCount > 0)
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(fetchedHeaderRowCount);

        headerRow = (Xx03ConfirmUpdSlipsVORowImpl)selectHeaderIter.first();
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount
    
      try
      {
        // COMMIT
        getTransaction().commit();
      }
      catch(OAException ex)
      {
        throw OAException.wrapperException(ex);
      }

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
    }
  } // confirmSave()
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * 承認階層クラスを取得する
   * @param なし
   * @return なし
   * @return String 承認階層クラス値
   */
  public String confirmRecognitionClass()
  {
    // 初期化処理
    String methodName = "confirmRecognitionClass";
    startProcedure(getClass().getName(), methodName);
    
    String retValue = null;
    Number recognitionClass;
    
    // ビュー・オブジェクトの取得
    Xx03ConfirmDispSlipsVOImpl    vo  = getXx03ConfirmDispSlipsVO1();
    if(vo.first() != null)
    {
      vo.first();
      Xx03ConfirmDispSlipsVORowImpl row = (Xx03ConfirmDispSlipsVORowImpl)vo.getCurrentRow();
      recognitionClass = row.getRecognitionClass();
      if(recognitionClass != null)
      {
        retValue = recognitionClass.toString();
      }
    }
    // 終了処理
    endProcedure(getClass().getName(), methodName);
    return retValue;
  }
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * 前受金ボタン表示区分取得
   * @param なし
   * @return 前受金表示区分
   */
  public String confirmPrePay()
  {
    // 初期化処理
    String methodName = "confirmPrePay";
    startProcedure(getClass().getName(), methodName);
    
    RowSetIterator selectDispIter = null;     
    int fetchedDispRowCount;
    String retStr = "N";  // 前受金表示区分

    try
    {
      Xx03ConfirmDispSlipsVOImpl    dispVo    = getXx03ConfirmDispSlipsVO1();
      Xx03ConfirmDispSlipsVORowImpl dispRow   = null;

      Xx03PrePayButtonVOImpl        prepayVo  = getXx03PrePayButtonVO1();
      Xx03PrePayButtonVORowImpl     prepayRow = null;

      //Ver11.5.10.1.6J 2006/01/16 Change Start
      //fetchedDispRowCount = dispVo.getFetchedRowCount();
      fetchedDispRowCount = dispVo.getRowCount();
      //Ver11.5.10.1.6J 2006/01/16 Change End
      selectDispIter      = dispVo.createRowSetIterator("selectDispIter");

      if (fetchedDispRowCount > 0)
      {
        selectDispIter.setRangeStart(0);
        selectDispIter.setRangeSize(fetchedDispRowCount);

        dispRow = (Xx03ConfirmDispSlipsVORowImpl)selectDispIter.first();

        if (dispRow != null)
        {
          // 伝票種別取得
          String slipType = dispRow.getSlipType();

          // 前受金表示区分取得
          prepayVo.initQuery(slipType);
          prepayRow = (Xx03PrePayButtonVORowImpl)prepayVo.first();
          
          if (prepayRow != null)
          {
            retStr = prepayRow.getAttribute12();
          }
        } // headerRow
      } // fetchedHeaderRocCount
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmDispSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);
      } // fetchedHeaderRowCount 
    
      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    finally
    {
      if(selectDispIter != null)
      {
        selectDispIter.closeRowSetIterator();
      }
    }
    return retStr;
  } // confirmPrePay()
  //ver11.5.10.1.6 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * 伝票種別が有効かを返す。
   * @return String 'Y':有効 'N':無効
   */
  public String retEnableSlipType()
  {

    Xx03ConfirmDispSlipsVOImpl hVo = getXx03ConfirmDispSlipsVO1();
    hVo.first();

    Xx03ConfirmDispSlipsVORowImpl hRow =
      (Xx03ConfirmDispSlipsVORowImpl)hVo.getCurrentRow();

    //Ver11.5.10.1.6C 2005/12/08 Change Start
    //Xx03SlipTypesLovVOImpl vo = getXx03SlipTypesLovVO1();
    Xx03EnableSlipTypeVOImpl vo = getXx03EnableSlipTypeVO1();
    //Ver11.5.10.1.6C 2005/12/08 Change End
    vo.initQuery(hRow.getSlipType());

    String retStr = "N";
    if (vo.first() != null)
    {
      retStr = "Y";
    }

    return retStr;
  }
  //ver11.5.10.1.6 Add End

  //Ver11.5.10.1.6G 2005/12/27 Add Start
  /**
   * 伝票種別が有効かを返す。
   * @return String 'Y':有効 'N':無効 'A':アプリ無し
   */
  public String retEnableSlipType2()
  {
    String retStr = "N";

    Xx03SlipTypesLovVOImpl    slipVo  = getXx03SlipTypesLovVO1();
    if (slipVo.first() == null)
    {
      retStr = "N";
    }
    else
    {
      Xx03SlipTypesLovVORowImpl slipRow = (Xx03SlipTypesLovVORowImpl)slipVo.getCurrentRow();
      String att14 = slipRow.getAttribute14();

      if (att14 == null || "".equals(att14))
      {
        retStr = "A";
      }
      else
      {
        retStr = "Y";
      }
    }

    return retStr;
  }
  //Ver11.5.10.1.6G 2005/12/27 Add End

  //ver11.5.10.2.3 Add Start
  /**
   * 伝票種別がメニューで有効かを返す。
   * @return String 'Y1':有効(自部門伝票) 'Y2':有効(他部門伝票)
   *                'N1':無効(自部門伝票) 'N2':無効(他部門伝票)
   */
  public String retEnableSlipType3()
  {

    Xx03ConfirmDispSlipsVOImpl hVo = getXx03ConfirmDispSlipsVO1();
    hVo.first();
    Xx03ConfirmDispSlipsVORowImpl hRow =
      (Xx03ConfirmDispSlipsVORowImpl)hVo.getCurrentRow();

    Xx03ChkUsrDepartmentVOImpl dVo = getXx03ChkUsrDepartmentVO1();
    dVo.initQuery(hRow.getEntryDepartment());
    dVo.first();
    Xx03ChkUsrDepartmentVORowImpl dRow =
      (Xx03ChkUsrDepartmentVORowImpl)dVo.getCurrentRow();
    Number dCnt = dRow.getCnt();
    
    Xx03GetArMenuSlipTypeVOImpl mVo = getXx03GetArMenuSlipTypeVO1();
    mVo.initQuery(hRow.getSlipType());
    mVo.first();
    Xx03GetArMenuSlipTypeVORowImpl mRow =
      (Xx03GetArMenuSlipTypeVORowImpl)mVo.getCurrentRow();
    Number mCnt = mRow.getCnt();

    String retStr = "";
    if (mCnt.intValue() != 0)
    {
      if(dCnt.intValue() != 0)
      {
        retStr = "Y1";
      }
      else
      {
        retStr = "Y2";
      }
    }
    else
    {
      if(dCnt.intValue() != 0)
      {
        retStr = "N1";
      }
      else
      {
        retStr = "N2";
      }
    }

    return retStr;
  }
  //ver11.5.10.2.3 Add End

  //ver11.5.10.3 Add Start
  /**
   * 顧客IDチェック
   * @param  customerId 顧客ID
   * @return exception  エラーリスト
   */
  public Vector checkCustomerId( Number customerId)           // 顧客ＩＤ
  {
    // エラーメッセージの準備
    OAException  msg         = null;                         // エラーメッセージ
    MessageToken slipNumTok  = null;                         // 伝票番号トークン
    Vector exception         = new Vector();
    byte         messageType = OAException.ERROR;            // エラータイプ

    // 顧客チェック（顧客ＩＤ存在時実行）
    if ( (customerId != null) && (!customerId.equals("")) )
    {
      int customerInfo = getCustomerId(customerId);
      if (customerInfo == 0)
      {
        msg = new OAException( "XXCFR" ,"APP-XXCFR1-10001" );
        exception.addElement(msg);
      }
    }
    return exception;
  }
  //ver11.5.10.3 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * ヘッダのマスタチェック
   * @param  headerRow  ヘッダ行
   * @param  methodName 呼出元メソッド名
   * @return exception  エラーリスト
   */
  //ver 11.5.10.1.6I Chg Start
  //public Vector validateHeader( Vector exception
  //                             ,String methodName
  //                             ,String slipNum              // 伝票番号
  //                             ,String slipType             // 伝票種別コード
  //                             ,Number transTypeId          // 取引ＩＤ
  //                             ,Number customerId           // 顧客ＩＤ
  //                             ,Number custOfficeId         // 顧客事業所ＩＤ
  //                             ,Number receiptMethodId      // 支払方法ＩＤ
  //                             ,Number termsId              // 支払条件ＩＤ
  //                             ,String currencyCode         // 通貨コード
  //                             ,Date   invoiceDate          // 請求書日付
  //                             ,String origInvoiceNum       // 修正元伝票番号
  //                             )
  public Vector validateHeader( Vector exception
                               ,String methodName
                               ,String slipNum              // 伝票番号
                               ,String slipType             // 伝票種別コード
                               ,Number transTypeId          // 取引ＩＤ
                               ,Number customerId           // 顧客ＩＤ
                               ,Number custOfficeId         // 顧客事業所ＩＤ
                               ,Number receiptMethodId      // 支払方法ＩＤ
                               ,Number termsId              // 支払条件ＩＤ
                               ,String currencyCode         // 通貨コード
                               ,Date   invoiceDate          // 請求書日付
                               ,String origInvoiceNum       // 修正元伝票番号
                               ,String wfStatus             // ワークフローステータス
                               ,Number approverId           // 承認者ID
                               ,String slipTypeApp          // 伝票種別アプリ
                               )
  //ver 11.5.10.1.6I Chg End
  {
    // エラーメッセージの準備
    OAException  msg         = null;                         // エラーメッセージ
    MessageToken slipNumTok  = null;                         // 伝票番号トークン
    byte         messageType = OAException.ERROR;            // エラータイプ
    
    // トークンの準備
    if (methodName.equals("checkAllValidation"))
    {
      // 一括承認からの呼出の場合、エラーメッセージに伝票番号追加
      slipNumTok = new MessageToken("SLIP_NUM", slipNum + ":");
    }
    else
    {
      // 確認画面からの呼出の場合、伝票番号は表示しない
      slipNumTok = new MessageToken("SLIP_NUM", "");
    }
    
    
    //ver 11.5.10.1.6I Add Start
    // 承認者チェック（承認者ＩＤ,伝票種別アプリ 存在時実行）
    if (    (approverId  != null) && (!approverId.equals("") )
         && (slipTypeApp != null) && (!slipTypeApp.equals(""))
         && (    (Xx03CommonUtil.STATUS_SAVE.equals(wfStatus)       )
              || (Xx03CommonUtil.STATUS_BEFORE_DEPT.equals(wfStatus))) )
    {
      ArrayList approverInfo = getApproverName(approverId, slipTypeApp);
      if (approverInfo.isEmpty())
      {
        // 承認者不正エラー
        msg = new OAException( "XX03" ,"APP-XX03-14154"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }
    //ver 11.5.10.1.6I Add End
    
    // 取引タイプチェック（取引タイプ,請求書日付,伝票種別コード 存在時実行）
    // かつ、取消伝票で無い場合（取り消しの場合は取引タイプ=取消で固定のためチェック不要）
    if (    (transTypeId != null) && (!transTypeId.equals(""))
         && (invoiceDate != null) && (!invoiceDate.equals(""))
         && (slipType    != null) && (!slipType.equals("")   )
         && (origInvoiceNum == null)                           )
    {
      ArrayList transTypeInfo = getTransTypeName(transTypeId ,invoiceDate ,slipType);
      if (transTypeInfo.isEmpty())
      { 
        msg = new OAException( "XX03" ,"APP-XX03-13060"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }
    
    // 顧客チェック（顧客ＩＤ存在時実行）
    if ( (customerId != null) && (!customerId.equals("")) )
    {
      ArrayList customerInfo = getCustomerName(customerId);
      if (customerInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13061"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }
  
    // 顧客事業所チェック（顧客ＩＤ,顧客事業所ＩＤ存在時実行）
    if (    (customerId   != null) && (!customerId.equals("")  )
         && (custOfficeId != null) && (!custOfficeId.equals("")) )
    {
      ArrayList custOfficeInfo = getCustOfficeName(custOfficeId, customerId);
      if (custOfficeInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13062"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
       exception.addElement(msg);
      }
    }

    //ver 11.5.10.2.6 Chg Start
    //// 通貨コードチェック（通貨コード,請求書日付存在時実行）
    //if (    (currencyCode != null) && (!currencyCode.equals(""))
    //     && (invoiceDate  != null) && (!invoiceDate.equals("") ) )
    // 通貨チェック（通貨コード 存在時実行）
    if ((currencyCode != null) && (!currencyCode.equals("")))
    //ver 11.5.10.2.6 Chg End
    {
      //ver 11.5.10.2.6 Chg Start
      //ArrayList currencyInfo = getCurrencyName(currencyCode, invoiceDate);
      //ver 11.5.10.2.10 Chg Start
      //ArrayList currencyInfo = getCurrencyName(currencyCode);
      ArrayList currencyInfo = getCurrencyName(currencyCode, invoiceDate);
      //ver 11.5.10.2.10 Chg End
      //ver 11.5.10.2.6 Chg End
      if (currencyInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-14150"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }

    // 支払方法チェック（支払方法ＩＤ,顧客事業所ＩＤ,通貨コード存在時実行）
    if (    (custOfficeId    != null) && (!custOfficeId.equals("")   )
         && (receiptMethodId != null) && (!receiptMethodId.equals(""))
         && (currencyCode    != null) && (!currencyCode.equals("")   )
         && (invoiceDate     != null) && (!invoiceDate.equals("")    ) )
    {
      ArrayList receiptMethodInfo = getReceiptMethodName(receiptMethodId, custOfficeId, currencyCode, invoiceDate);
      if (receiptMethodInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13063"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }

    // 支払条件チェック（支払条件ＩＤ,請求書日付存在時実行）
    if (    (termsId     != null) && (!termsId.equals("")    )
         && (invoiceDate != null) && (!invoiceDate.equals("")) )
    {
      ArrayList termsInfo = getTermsName(termsId, invoiceDate);
      if (termsInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13064"
                              ,new MessageToken[]{slipNumTok} ,messageType ,null);
        exception.addElement(msg);
      }
    }

    return exception;
  }

  /**
   * 取引タイプ名称取得
   * @param  transTypeId 取引タイプＩＤ
   * @param  slipType    伝票種別
   * @return returnInfo  取引タイプ名称
   */
  public ArrayList getTransTypeName(Number transTypeId ,Date invoiceDate ,String slipType)
  {
    String    transTypeName = null;
    ArrayList returnInfo    = new ArrayList();

    Xx03GetTransTypeNameVOImpl    vo  = getXx03GetTransTypeNameVO1();
    Xx03GetTransTypeNameVORowImpl row = null;

    vo.initQuery(transTypeId ,invoiceDate ,slipType);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetTransTypeNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        transTypeName = row.getName();
      }
      returnInfo.add(transTypeName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getTransTypeName

  //ver11.5.10.3 Add Start
  /**
   * 顧客ID取得（セキュリティチェック）
   * @param  customerId  顧客ID
   * @return returnInfo  顧客ID
   */
   public int getCustomerId(Number customerId)
   {
     int returnInfo    = 0;

     Xx03ChkArCustomerVOImpl    vo  = Xx03ChkArCustomerVO1();

     vo.initQuery(customerId);

     Xx03ChkArCustomerVORowImpl row = (Xx03ChkArCustomerVORowImpl)vo.first();
     Number customer_cnt = row.getCustomerCnt();
     if (customer_cnt.intValue() != 0)
     {
       returnInfo = 1;
     }
     return returnInfo; 
   } // getCustomerId
  //ver11.5.10.3 Add End

  /**
   * 顧客名称取得
   * @param  customerId  顧客ＩＤ
   * @param  transTypeId 取引タイプＩＤ
   * @param  slipType    伝票種別コード
   * @return returnInfo  顧客名称
   */
  public ArrayList getCustomerName(Number customerId)
  {
    String    customerName  = null;
    ArrayList returnInfo    = new ArrayList();

    Xx03GetArCustomerNameVOImpl    vo  = getXx03GetArCustomerNameVO1();
    Xx03GetArCustomerNameVORowImpl row = null;

    vo.initQuery(customerId);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetArCustomerNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        customerName = row.getName();
      }
      returnInfo.add(customerName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getCustomerName

  /**
   * 顧客事業所名称取得
   * @param  custOfficeId 顧客事業所ＩＤ
   * @param  customerId   顧客ＩＤ
   * @return returnInfo   顧客事業所名称
   */
  public ArrayList getCustOfficeName(Number custOfficeId, Number customerId)
  {
    String    custOfficeName = null;
    ArrayList returnInfo     = new ArrayList();

    Xx03GetArCustSiteNameVOImpl    vo  = getXx03GetArCustSiteNameVO1();
    Xx03GetArCustSiteNameVORowImpl row = null;

    vo.initQuery(custOfficeId, customerId);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetArCustSiteNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        custOfficeName = row.getName();
      }
      returnInfo.add(custOfficeName);
    }    
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getCustOfficeName

  /**
   * 通貨名称取得
   * @param  invoiceCurrencyCode  通貨コード
   * @return returnInfo           通貨名称
   */
  // ver 11.5.10.2.6 Chg Start
  //public ArrayList getCurrencyName(String invoiceCurrencyCode, Date invoiceDate)
  //ver 11.5.10.2.10 Chg Start
  //public ArrayList getCurrencyName(String invoiceCurrencyCode)
  public ArrayList getCurrencyName(String invoiceCurrencyCode, Date invoiceDate)
  //ver 11.5.10.2.10 Chg End
  // ver 11.5.10.2.6 Chg End
  {
    String    currencyName = null;
    ArrayList returnInfo   = new ArrayList();

    Xx03GetCurrencyNameVOImpl    vo  = getXx03GetCurrencyNameVO1();
    Xx03GetCurrencyNameVORowImpl row = null;

    // ver 11.5.10.2.6 Chg Start
    //vo.initQuery(invoiceCurrencyCode, invoiceDate);
    //ver 11.5.10.2.10 Chg Start
    //vo.initQuery(invoiceCurrencyCode);
    vo.initQuery(invoiceCurrencyCode, invoiceDate);
    //ver 11.5.10.2.10 Chg End
    // ver 11.5.10.2.6 Chg End
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetCurrencyNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        currencyName = row.getName();
      }
      returnInfo.add(currencyName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getCurrencyName

  /**
   * 支払方法名称取得
   * @param  receiptMethodId 顧客事業所ＩＤ
   * @param  receiptMethodId 顧客ＩＤ
   * @param  currencyCode    通貨コード
   * @return returnInfo      支払方法名称
   */
  public ArrayList getReceiptMethodName(Number receiptMethodId, Number custOfficeId, String currencyCode, Date invoiceDate)
  {
    String    receiptMethodName = null;
    ArrayList returnInfo        = new ArrayList();

    Xx03GetReceiptMethodNameVOImpl    vo  = getXx03GetReceiptMethodNameVO1();
    Xx03GetReceiptMethodNameVORowImpl row = null;

    vo.initQuery(receiptMethodId, custOfficeId, currencyCode, invoiceDate);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetReceiptMethodNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        receiptMethodName = row.getName();
      }
      returnInfo.add(receiptMethodName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getReceiptMethodName

  /**
   * 支払条件名称取得
   * @param  termsId     支払条件ＩＤ
   * @param  invoiceDate 請求書日付
   * @return returnInfo  支払条件名称
   */
  public ArrayList getTermsName(Number termsId, Date invoiceDate)
  {
    String    termsName  = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetTermsNameVOImpl    vo  = getXx03GetTermsNameVO1();
    Xx03GetTermsNameVORowImpl row = null;

    vo.initQuery(termsId, invoiceDate);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetTermsNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        termsName = row.getName();
      }
      returnInfo.add(termsName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getTermsName

  //ver 11.5.10.1.6I Add Start
  /**
   * 承認者名称取得
   * @param  approverId   承認者ＩＤ
   * @param  slipTypeApp  伝票種別アプリ
   * @return returnInfo   承認者名称
   */
  public ArrayList getApproverName(Number approverId, String slipTypeApp)
  {
    String    approverName = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetApproverNameVOImpl    vo  = getXx03GetApproverNameVO1();
    Xx03GetApproverNameVORowImpl row = null;

    vo.initQuery(approverId, slipTypeApp);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetApproverNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        approverName = row.getName();
      }
      returnInfo.add(approverName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo;
  } // getApproverName
  //ver 11.5.10.1.6I Add End

  /**
   * 明細のマスタチェック
   * @param  headerRow  ヘッダー行
   * @param  lineRow    明細行
   * @param  exception  エラーリスト
   * @param  count      明細行数
   * @param  methodName 呼出元メソッド名
   * @return exception  エラーリスト
   */
  //Ver11.5.10.1.6E 2005/12/26 Change Start
  //public Vector validateLine( Vector exception
  //                           ,int    count
  //                           ,String methodName
  //                           ,String slipNum              // 伝票番号
  //                           ,String slipType             // 伝票種別コード
  //                           ,Date   invoiceDate          // 請求書日付
  //                           ,Number slipLineType         // 請求内容ＩＤ
  //                           ,String slipLineUom          // 単位
  //                           )
  public Vector validateLine( Vector exception
                             ,int    count
                             ,String methodName
                             ,String slipNum              // 伝票番号
                             //ver 11.5.10.1.6Q Del Start
                             //,String slipType             // 伝票種別コード
                             //ver 11.5.10.1.6Q Del End
                             ,Date   invoiceDate          // 請求書日付
                             //ver 11.5.10.1.6Q Del Start
                             //,Number slipLineType         // 請求内容ＩＤ
                             //ver 11.5.10.1.6Q Del End
                             ,String slipLineUom          // 単位
                             ,String slipLineTaxName      // 税名称
                             ,String slipLineTaxCode      // 税コード
                             //Ver11.5.10.1.6P Add Start
                             ,Number slipLineTaxId        // 税ID
                             //Ver11.5.10.1.6P Add End
                             //Ver11.5.10.1.6R Add Start
                             ,String includesTaxFlag      // 内税フラグ
                             //Ver11.5.10.1.6R Add End
                             )
  //Ver11.5.10.1.6E 2005/12/26 Change End
  {
    // エラーメッセージの準備
    OAException msg = null;               // エラーメッセージ
    byte messageType = OAException.ERROR; // エラータイプ
    MessageToken countTok = null;         // 行番号トークン
    MessageToken slipNumTok = null;       // 伝票番号トークン
    String strCount = new Integer(count + 1).toString();
    
    // トークンの準備
    if (methodName.equals("checkAllValidation"))
    {
      // 一括承認からの呼出の場合、エラーメッセージに伝票番号追加
      slipNumTok = new MessageToken("SLIP_NUM", slipNum + ":");
    }
    else
    {
      // 確認画面からの呼出の場合、伝票番号は表示しない
      slipNumTok = new MessageToken("SLIP_NUM", "");
    }
    countTok = new MessageToken("TOK_COUNT", strCount);
    
    //ver 11.5.10.1.6Q Del Start
    //// 請求内容チェック（請求内容ＩＤ,請求書日付存在時実行）
    //if (    (slipLineType != null) && (!slipLineType.equals(""))
    //     && (invoiceDate  != null) && (!invoiceDate.equals("") )
    //     && (slipType     != null) && (!slipType.equals("")    ))
    //{
    //  ArrayList slipLineTypeInfo = getSlipLineTypeName(slipLineType, invoiceDate, slipType);
    //  if (slipLineTypeInfo.isEmpty())
    //  {
    //    msg = new OAException( "XX03" ,"APP-XX03-13065"
    //                          ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
    //    exception.addElement(msg);
    //  }
    //}
    //ver 11.5.10.1.6Q Del End

    //ver 11.5.10.2.6 Chg Start
    //// 単位チェック（単位存在時実行）
    //if (    (slipLineUom != null) && (!slipLineUom.equals(""))
    //     && (invoiceDate != null) && (!invoiceDate.equals("")) )
    // 単位チェック（単位存在時実行）
    if ((slipLineUom != null) && (!slipLineUom.equals("")))
    //ver 11.5.10.2.6 Chg End
    {
      //ver 11.5.10.2.6 Chg Start
      //ArrayList uomInfo = getUomID(slipLineUom, invoiceDate);
      ArrayList uomInfo = getUomID(slipLineUom);
      //ver 11.5.10.2.6 Chg End
      if (uomInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-13066"
                              ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
        exception.addElement(msg);         
      }
    }
    
    //Ver11.5.10.1.6E 2005/12/26 Change Start
    // 税金コードチェック（請求書日付存在時実行）
    if (    (invoiceDate     != null) && (!invoiceDate.equals("")    )
         && (slipLineTaxName != null) && (!slipLineTaxName.equals(""))
         && (slipLineTaxCode != null) && (!slipLineTaxCode.equals("")) )
    {
      ArrayList slipLineTaxInfo = getSlipLineTaxName(slipLineTaxName, slipLineTaxCode, invoiceDate);
      if (slipLineTaxInfo.isEmpty())
      {
        msg = new OAException( "XX03" ,"APP-XX03-14151"
                              ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
        exception.addElement(msg);
      }
      //Ver11.5.10.1.6P Add Start
      else
      {
        Number getTaxId = (Number)slipLineTaxInfo.get(1);
        //Ver11.5.10.1.6R Add Start
        String getIncTaxFlag = (String)slipLineTaxInfo.get(2);
        //Ver11.5.10.1.6R Add End
        if (!slipLineTaxId.equals(getTaxId))
        {
          msg = new OAException( "XX03" ,"APP-XX03-14151"
                                ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
          exception.addElement(msg);
        }
        //Ver11.5.10.1.6R Add Start
        else if (!getIncTaxFlag.equals(includesTaxFlag))
        {
          msg = new OAException( "XX03" ,"APP-XX03-13070"
                                ,new MessageToken[]{slipNumTok ,countTok} ,messageType ,null);
          exception.addElement(msg);
        }
        //Ver11.5.10.1.6R Add End
      }
      //Ver11.5.10.1.6P Add End
    }
    //Ver11.5.10.1.6E 2005/12/26 Change End
    
    return exception;
  }

  /**
   * 請求内容名称取得
   * @param  slipLinetype 請求内容ＩＤ
   * @param  invoiceDate  請求書日付
   * @return returnInfo   請求内容名称   
   */
  public ArrayList getSlipLineTypeName(Number slipLineType, Date invoiceDate, String slipType)
  {
    String    slipLineTypeName = null;
    ArrayList returnInfo       = new ArrayList();

    Xx03GetArLinesNameVOImpl    vo  = getXx03GetArLinesNameVO1();
    Xx03GetArLinesNameVORowImpl row = null;

    vo.initQuery(slipLineType, invoiceDate, slipType);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetArLinesNameVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        slipLineTypeName = row.getName();
      }
      returnInfo.add(slipLineTypeName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getSlipLineTypeName

  /**
   * 単位ＩＤ取得
   * @param  slipLineUom  単位名称
   * @return returnInfo   単位ＩＤ   
   */
  // ver 11.5.10.2.6 Chg Start
  //public ArrayList getUomID(String slipLineUom, Date invoiceDate)
  public ArrayList getUomID(String slipLineUom)
  // ver 11.5.10.2.6 Chg End
  {
    String    uomName    = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetUomCodeVOImpl    vo  = getXx03GetUomCodeVO1();
    Xx03GetUomCodeVORowImpl row = null;

    // ver 11.5.10.2.6 Chg Start
    //vo.initQuery(slipLineUom, invoiceDate);
    vo.initQuery(slipLineUom);
    // ver 11.5.10.2.6 Chg End
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetUomCodeVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        uomName = row.getName();
      }
      returnInfo.add(uomName);
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  } // getUomID
  //ver11.5.10.1.6 Add End

  //Ver11.5.10.1.6E 2005/12/26 Add Start
  public ArrayList getSlipLineTaxName(String slipLineTaxName, String slipLineTaxCode, Date invoiceDate)
  {
    String    taxName    = null;
    ArrayList returnInfo = new ArrayList();

    Xx03GetTaxColVOImpl    vo  = getXx03GetTaxColVO1();
    Xx03GetTaxColVORowImpl row = null;

    vo.initQuery(slipLineTaxCode, invoiceDate);
    RowSetIterator selectIter = vo.createRowSetIterator("selectIter");

    int rowCount = vo.getRowCount();
    if (rowCount == 1)
    {
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(rowCount);

      row = (Xx03GetTaxColVORowImpl)selectIter.getRowAtRangeIndex(0);
      
      if (row != null)
      {
        String taxCol = row.getTaxCol();
        if (slipLineTaxName.equals(taxCol))
        {
          taxName = taxCol;
          returnInfo.add(taxName);
          //Ver11.5.10.1.6P Add Start
          returnInfo.add(row.getTaxId());
          //Ver11.5.10.1.6P Add End
          //Ver11.5.10.1.6R Add Start
          returnInfo.add(row.getAmountIncludesTaxFlag());
          //Ver11.5.10.1.6R Add End
        }
      }
    }
    selectIter.closeRowSetIterator();
    return returnInfo; 
  }
  //Ver11.5.10.1.6E 2005/12/26 Add End

  //ver11.5.10.1.6 Add Start
  /**
   * 確認でのValidationチェック
   * @param なし
   * @return 
   */
  public Vector checkConfValidation()
  {
    // 初期化処理
    String methodName = "checkConfValidation";
    startProcedure(getClass().getName(), methodName);

    Vector msg = new Vector();

    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;

    int getHeaderRowCount;
    int getLineRowCount;

    //ver 11.5.10.1.6I Add Start
    RowSetIterator selectUpdIter = null;    
    int getUpdRowCount;
    //ver 11.5.10.1.6I Add End

    try
    {
      // ビュー・オブジェクトの取得
      OAViewObject headerVo = getXx03ConfirmDispSlipsVO1();
      OAViewObject lineVo   = getXx03ConfirmDispSlipsLineVO1();

      Xx03ConfirmDispSlipsVORowImpl     headerRow = null;
      Xx03ConfirmDispSlipsLineVORowImpl lineRow   = null;

      getHeaderRowCount = headerVo.getRowCount();
      getLineRowCount   = lineVo.getRowCount();

      selectHeaderIter  = headerVo.createRowSetIterator("selectHeaderIter");
      selectLineIter    = lineVo.createRowSetIterator("selectLineIter");

      //ver 11.5.10.1.6I Add Start
      OAViewObject updVo  = getXx03ConfirmUpdSlipsVO1();
      Xx03ConfirmUpdSlipsVORowImpl updRow  = null;
      getUpdRowCount  = updVo.getRowCount();
      selectUpdIter  = updVo.createRowSetIterator("selectUpdIter");
      //ver 11.5.10.1.6I Add End

      //ver 11.5.10.1.6I Chg Start
      //if (getHeaderRowCount > 0)
      if ((getHeaderRowCount > 0) && (getUpdRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(getHeaderRowCount);
        headerRow = (Xx03ConfirmDispSlipsVORowImpl)selectHeaderIter.first();

        //ver 11.5.10.1.6I Add Start
        selectUpdIter.setRangeStart(0);
        selectUpdIter.setRangeSize(getUpdRowCount);
        updRow = (Xx03ConfirmUpdSlipsVORowImpl)selectUpdIter.first();
        //ver 11.5.10.1.6I Add End

        //ver 11.5.10.1.6I Chg Start
        //if (headerRow != null)
        if ((headerRow != null) && (updRow != null))
        {
        //ver 11.5.10.1.6I Chg End
          // Validation
          // チェック対象
          //ver 11.5.10.1.6I Chg Start
          //msg = (Vector)validateHeader( msg
          //                             ,methodName
          //                             ,headerRow.getReceivableNum()       // 伝票番号
          //                             ,headerRow.getSlipType()            // 伝票種別コード
          //                             ,headerRow.getTransTypeId()         // 取引ＩＤ
          //                             ,headerRow.getCustomerId()          // 顧客ＩＤ
          //                             ,headerRow.getCustomerOfficeId()    // 顧客事業所ＩＤ
          //                             ,headerRow.getReceiptMethodId()     // 支払方法ＩＤ
          //                             ,headerRow.getTermsId()             // 支払条件ＩＤ
          //                             ,headerRow.getInvoiceCurrencyCode() // 通貨コード
          //                             ,headerRow.getInvoiceDate()         // 請求書日付
          //                             ,headerRow.getOrigInvoiceNum()      // 修正元伝票番号
          //                             );
          msg = (Vector)validateHeader( msg
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // 伝票番号
                                       ,headerRow.getSlipType()            // 伝票種別コード
                                       ,headerRow.getTransTypeId()         // 取引ＩＤ
                                       ,headerRow.getCustomerId()          // 顧客ＩＤ
                                       ,headerRow.getCustomerOfficeId()    // 顧客事業所ＩＤ
                                       ,headerRow.getReceiptMethodId()     // 支払方法ＩＤ
                                       ,headerRow.getTermsId()             // 支払条件ＩＤ
                                       ,headerRow.getInvoiceCurrencyCode() // 通貨コード
                                       ,headerRow.getInvoiceDate()         // 請求書日付
                                       ,headerRow.getOrigInvoiceNum()      // 修正元伝票番号
                                       ,headerRow.getWfStatus()            // ワークフローステータス
                                       ,updRow.getApproverPersonId()       // 承認者ＩＤ
                                       ,headerRow.getSlipTypeApp()         // 伝票種別アプリ
                                       );
          //ver 11.5.10.1.6I Chg End
        } // headerRow
      } // getHeaderRocCount
      //ver 11.5.10.1.6I Chg Start
      //else
      else if (!(getHeaderRowCount > 0))
      //ver 11.5.10.1.6I Chg End
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "getXx03ConfirmDispSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6I Add Start
      else if (!(getUpdRowCount > 0))
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ConfirmUpdSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // updRowCount
      //ver 11.5.10.1.6I Add End

      if (getLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(getLineRowCount);

        for (int i=0; i<getLineRowCount; i++)
        {
          lineRow = (Xx03ConfirmDispSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // Validation

            
            //Ver11.5.10.1.6E 2005/12/26 Change Start
            //msg = (Vector)validateLine( msg
            //                           ,i
            //                           ,methodName
            //                           ,headerRow.getReceivableNum()       // 伝票番号
            //                           ,headerRow.getSlipType()            // 伝票種別コード
            //                           ,headerRow.getInvoiceDate()         // 請求書日付
            //                           ,lineRow.getSlipLineType()          // 請求内容ＩＤ
            //                           ,lineRow.getSlipLineUom()           // 単位
            //                           );
            msg = (Vector)validateLine( msg
                                       ,i
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // 伝票番号
                                       //ver 11.5.10.1.6Q Del Start
                                       //,headerRow.getSlipType()            // 伝票種別コード
                                       //ver 11.5.10.1.6Q Del End
                                       ,headerRow.getInvoiceDate()         // 請求書日付
                                       //ver 11.5.10.1.6Q Del Start
                                       //,lineRow.getSlipLineType()          // 請求内容ＩＤ
                                       //ver 11.5.10.1.6Q Del End
                                       ,lineRow.getSlipLineUom()           // 単位
                                       ,lineRow.getTaxName()
                                       ,lineRow.getTaxCode()
                                       //Ver11.5.10.1.6P Add Start
                                       ,lineRow.getTaxId()
                                       //Ver11.5.10.1.6P Add End
                                       //Ver11.5.10.1.6R Add Start
                                       ,lineRow.getAmountIncludesTaxFlag()
                                       //Ver11.5.10.1.6R Add End
                                       );
            //Ver11.5.10.1.6E 2005/12/26 Change End
          } // lineRow != null
        } // for loop
      } // getLineRowCount > 0

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    //ver 11.5.10.1.6Q Add Start
    catch (OAException oaEx)
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
      if(selectUpdIter != null)
      {
        selectUpdIter.closeRowSetIterator();
      }
      throw new OAException(oaEx.getMessage());
    }
    //ver 11.5.10.1.6Q Add End
    //ver 11.5.10.1.6Q Chg Start
    //finally
    //{
    //  if(selectHeaderIter != null)
    //  {
    //    selectHeaderIter.closeRowSetIterator();
    //  }
    //  if(selectLineIter != null)
    //  {
    //    selectLineIter.closeRowSetIterator();
    //  }
    //  //Ver11.5.10.1.6N Add Start
    //  if(selectUpdIter != null)
    //  {
    //    selectUpdIter.closeRowSetIterator();
    //  }
    //  //Ver11.5.10.1.6N Add End
    //  return msg;
    //}
    selectHeaderIter.closeRowSetIterator();
    selectLineIter.closeRowSetIterator();
    selectUpdIter.closeRowSetIterator();
    return msg;
    //ver 11.5.10.1.6Q Chg End
  } // checkConfValidation()

  //ver11.5.10.1.6B Start
  /**
   * Validationチェック
   * @param なし
   * @return 
   */
  //ver 11.5.10.1.6Q Chg Start
  //public Vector checkAllValidation()
  public Vector checkAllValidation(Number receivableId)
  //ver 11.5.10.1.6Q Chg End
  {
    // 初期化処理
    String methodName = "checkAllValidation";
    startProcedure(getClass().getName(), methodName);

    Vector msg = new Vector();

    RowSetIterator selectHeaderIter = null;
    RowSetIterator selectLineIter = null;

    int getHeaderRowCount;
    int getLineRowCount;

    //ver 11.5.10.1.6I Add Start
    RowSetIterator selectSlipIter = null;    
    int getSlipRowCount;
    //ver 11.5.10.1.6I Add End

    try
    {
      // ビュー・オブジェクトの取得
      //ver 11.5.10.1.6Q Chg Start
      //OAViewObject headerVo = getXx03ReceivableSlipsVO1();
      //OAViewObject lineVo   = getXx03ReceivableSlipsLineVO1();
      Xx03ReceivableSlipsVOImpl     headerVo = getXx03ReceivableSlipsVO1();
      Xx03ReceivableSlipsLineVOImpl lineVo   = getXx03ReceivableSlipsLineVO2();
      //ver 11.5.10.1.6Q Chg End

      Xx03ReceivableSlipsVORowImpl     headerRow = null;
      Xx03ReceivableSlipsLineVORowImpl lineRow   = null;

      //ver 11.5.10.1.6Q Add Start
      headerVo.initQuery(receivableId, new Boolean(true));
      lineVo.initQuery(receivableId);
      //ver 11.5.10.1.6Q Add End

      getHeaderRowCount = headerVo.getRowCount();
      getLineRowCount   = lineVo.getRowCount();

      selectHeaderIter = headerVo.createRowSetIterator("selectHeaderIter");
      selectLineIter   = lineVo.createRowSetIterator("selectLineIter");

      //ver 11.5.10.1.6I Add Start
      //ver 11.5.10.1.6Q Del Start
      //OAViewObject slipVo  = getXx03SlipTypesLovVO1();
      //Xx03SlipTypesLovVORowImpl slipRow  = null;
      //getSlipRowCount  = slipVo.getRowCount();
      //selectSlipIter  = slipVo.createRowSetIterator("selectSlipIter");
      //ver 11.5.10.1.6Q Del End
      //ver 11.5.10.1.6I Add End

      //ver 11.5.10.1.6I Chg Start
      //if (getHeaderRowCount > 0)
      //ver 11.5.10.1.6Q Chg Start
      //if ((getHeaderRowCount > 0) && (getSlipRowCount > 0))
      if (getHeaderRowCount > 0)
      //ver 11.5.10.1.6Q Chg End
      //ver 11.5.10.1.6I Chg End
      {
        selectHeaderIter.setRangeStart(0);
        selectHeaderIter.setRangeSize(getHeaderRowCount);
        headerRow = (Xx03ReceivableSlipsVORowImpl)selectHeaderIter.first();

        //ver 11.5.10.1.6Q Add Start
        Xx03SlipTypesLovVOImpl    slipVo  = getXx03SlipTypesLovVO2();
        Xx03SlipTypesLovVORowImpl slipRow = null;
        slipVo.initQuery(headerRow.getSlipType());
        getSlipRowCount  = slipVo.getRowCount();
        selectSlipIter  = slipVo.createRowSetIterator("selectSlipIter");
        if (getSlipRowCount > 0)
        {
        //ver 11.5.10.1.6Q Add End

          //ver 11.5.10.1.6I Add Start
          selectSlipIter.setRangeStart(0);
          selectSlipIter.setRangeSize(getSlipRowCount);
          slipRow = (Xx03SlipTypesLovVORowImpl)selectSlipIter.first();
          //ver 11.5.10.1.6I Add End

          //ver 11.5.10.1.6I Chg Start
          //if (headerRow != null){
          if ((headerRow != null) && (slipRow != null))
          {
          //ver 11.5.10.1.6I Chg End
            // チェック対象
            //ver 11.5.10.1.6I Chg Start
            //msg = (Vector)validateHeader( msg
            //                             ,methodName
            //                             ,headerRow.getReceivableNum()       // 伝票番号
            //                             ,headerRow.getSlipType()            // 伝票種別コード
            //                             ,headerRow.getTransTypeId()         // 取引ＩＤ
            //                             ,headerRow.getCustomerId()          // 顧客ＩＤ
            //                             ,headerRow.getCustomerOfficeId()    // 顧客事業所ＩＤ
            //                             ,headerRow.getReceiptMethodId()     // 支払方法ＩＤ
            //                             ,headerRow.getTermsId()             // 支払条件ＩＤ
            //                             ,headerRow.getInvoiceCurrencyCode() // 通貨コード
            //                             ,headerRow.getInvoiceDate()         // 請求書日付
            //                             ,headerRow.getOrigInvoiceNum()      // 修正元伝票番号
            //                             );
            msg = (Vector)validateHeader( msg
                                         ,methodName
                                         ,headerRow.getReceivableNum()       // 伝票番号
                                         ,headerRow.getSlipType()            // 伝票種別コード
                                         ,headerRow.getTransTypeId()         // 取引ＩＤ
                                         ,headerRow.getCustomerId()          // 顧客ＩＤ
                                         ,headerRow.getCustomerOfficeId()    // 顧客事業所ＩＤ
                                         ,headerRow.getReceiptMethodId()     // 支払方法ＩＤ
                                         ,headerRow.getTermsId()             // 支払条件ＩＤ
                                         ,headerRow.getInvoiceCurrencyCode() // 通貨コード
                                         ,headerRow.getInvoiceDate()         // 請求書日付
                                         ,headerRow.getOrigInvoiceNum()      // 修正元伝票番号
                                         ,headerRow.getWfStatus()            // ワークフローステータス
                                         ,headerRow.getApproverPersonId()    // 承認者ＩＤ
                                         ,slipRow.getAttribute14()           // 伝票種別アプリ
                                         );
            //ver 11.5.10.1.6I Chg End
          } // headerRow
        //ver 11.5.10.1.6Q Add Start
        }
        else
        {
          // エラー・メッセージ
          MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03SlipTypesLovVO2")};
          throw new OAException("XX03", "APP-XX03-13034", tokens);
        } // updRowCount
        //ver 11.5.10.1.6Q Add End
      } // getHeaderRocCount
      //ver 11.5.10.1.6I Chg Start
      //else
      //ver 11.5.10.1.6Q Chg Start
      //else if (!(getHeaderRowCount > 0))
      else
      //ver 11.5.10.1.6Q Chg End
      //ver 11.5.10.1.6I Chg End
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsVO1")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6I Add Start
      //ver 11.5.10.1.6Q Del Start
      //else if (!(getSlipRowCount > 0))
      //{
      //  // エラー・メッセージ
      //  MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03SlipTypesLovVO1")};
      //  throw new OAException("XX03", "APP-XX03-13034", tokens);        
      //} // updRowCount
      //ver 11.5.10.1.6Q Del End
      //ver 11.5.10.1.6I Add End

      if (getLineRowCount > 0)
      {
        selectLineIter.setRangeStart(0);
        selectLineIter.setRangeSize(getLineRowCount);
        for (int i=0; i<getLineRowCount; i++)
        {
          lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectLineIter.getRowAtRangeIndex(i);

          if (lineRow != null)
          {
            // Validation


            //Ver11.5.10.1.6E 2005/12/26 Change Start
            //msg = (Vector)validateLine( msg
            //                           ,i
            //                           ,methodName
            //                           ,headerRow.getReceivableNum()       // 伝票番号
            //                          ,headerRow.getSlipType()            // 伝票種別コード
            //                           ,headerRow.getInvoiceDate()         // 請求書日付
            //                           ,lineRow.getSlipLineType()          // 請求内容ＩＤ
            //                           ,lineRow.getSlipLineUom()           // 単位
            //                           );
            msg = (Vector)validateLine( msg
                                       ,i
                                       ,methodName
                                       ,headerRow.getReceivableNum()       // 伝票番号
                                       //ver 11.5.10.1.6Q Del Start
                                       //,headerRow.getSlipType()            // 伝票種別コード
                                       //ver 11.5.10.1.6Q Del End
                                       ,headerRow.getInvoiceDate()         // 請求書日付
                                       //ver 11.5.10.1.6Q Del Start
                                       //,lineRow.getSlipLineType()          // 請求内容ＩＤ
                                       //ver 11.5.10.1.6Q Del End
                                       ,lineRow.getSlipLineUom()           // 単位
                                       ,lineRow.getTaxName()
                                       ,lineRow.getTaxCode()
                                       //Ver11.5.10.1.6P Add Start
                                       ,lineRow.getTaxId()
                                       //Ver11.5.10.1.6P Add End
                                       //Ver11.5.10.1.6R Add Start
                                       ,lineRow.getAmountIncludesTaxFlag()
                                       //Ver11.5.10.1.6R Add End
                                       );
            //Ver11.5.10.1.6E 2005/12/26 Change End
          } // lineRow != null
        } // for loop
      } // getLineRowCount > 0
      //ver 11.5.10.1.6Q Add Start
      else
      {
        // エラー・メッセージ
        MessageToken[] tokens = {new MessageToken("OBJECT_NAME", "Xx03ReceivableSlipsLineVO2")};
        throw new OAException("XX03", "APP-XX03-13034", tokens);        
      } // getHeaderRowCount
      //ver 11.5.10.1.6Q Add Start

      // 終了処理
      endProcedure(getClass().getName(), methodName);
    }
    //ver 11.5.10.1.6Q Add Start
    catch (OAException oaEx)
    {
      if(selectHeaderIter != null)
      {
        selectHeaderIter.closeRowSetIterator();
      }
      if(selectLineIter != null)
      {
        selectLineIter.closeRowSetIterator();
      }
      if(selectSlipIter != null)
      {
        selectSlipIter.closeRowSetIterator();
      }
      throw new OAException(oaEx.getMessage());
    }
    //ver 11.5.10.1.6Q Add End
    //ver 11.5.10.1.6Q Chg Start
    //finally
    //{
    //  if(selectHeaderIter != null)
    //  {
    //    selectHeaderIter.closeRowSetIterator();
    //  }
    //  if(selectLineIter != null)
    //  {
    //    selectLineIter.closeRowSetIterator();
    //  }
    //  return msg;
    //}
    selectHeaderIter.closeRowSetIterator();
    selectLineIter.closeRowSetIterator();
    selectSlipIter.closeRowSetIterator();
    return msg;
    //ver 11.5.10.1.6Q Chg End
  } // checkAllValidation()
  //ver11.5.10.1.6B End

  //ver11.5.10.1.6 Add End

  //ver11.5.10.2.3 Add Start
  /**
   * 申請でのValidationチェック
   * @param なし
   * @return 
   */
  public Vector checkApplyValidation()
  {
    // 初期化処理
    String methodName = "checkApplyValidation";
    startProcedure(getClass().getName(), methodName);


    OAException  msg     = null;                         // エラーメッセージ
    Vector exception     = new Vector();
    Vector exceptionConf = new Vector();

    // ビュー・オブジェクトの取得
    Xx03ConfirmDispSlipsVOImpl headerVo = getXx03ConfirmDispSlipsVO1();
    Xx03ConfirmDispSlipsVORowImpl headerRow =
          (Xx03ConfirmDispSlipsVORowImpl)headerVo.first();

    Xx03GetArMenuSlipTypeVOImpl menuVo = getXx03GetArMenuSlipTypeVO1();
    menuVo.initQuery(headerRow.getSlipType());
    Xx03GetArMenuSlipTypeVORowImpl menuRow =
          (Xx03GetArMenuSlipTypeVORowImpl)menuVo.first();
    Number mCnt = menuRow.getCnt();

    if (mCnt.intValue() == 0)
    {
      //伝票種別無効エラー
      msg = new OAException( "XX03" ,"APP-XX03-14152");
      exception.addElement(msg);
    }

    exceptionConf = checkConfValidation();
    if (!exceptionConf.isEmpty())
    {
      //ver 11.5.10.2.4 Chg Start
      //exception.addElement(exceptionConf);
      exception.addAll(exceptionConf);
      //ver 11.5.10.2.4 Chg End
    }

    //ver 11.5.10.3 Add Start
    //顧客IDセキュリティチェック
    exceptionConf = checkCustomerId(headerRow.getCustomerId()); // 顧客ＩＤ
    if (!exceptionConf.isEmpty())
    {
      exception.addAll(exceptionConf);
    }
    //ver 11.5.10.3 Add End

    // 終了処理
    endProcedure(getClass().getName(), methodName);
    
    return exception;
  } // checkApplyValidation()
  //ver11.5.10.2.3 Add End

  //ver 11.5.10.1.6I Add Start
  /**
   * デフォルト承認者を取得する。
   */
  public void getDefaultApprover ()
  {
    // 変更フラグ 
    boolean changeFlag = false;

    Xx03ConfirmDispSlipsVOImpl    hVo  = getXx03ConfirmDispSlipsVO1();
    Xx03ConfirmDispSlipsVORowImpl hRow = null;
    hVo.first();
    hRow = (Xx03ConfirmDispSlipsVORowImpl)hVo.getCurrentRow();

    String slipTypeApp = hRow.getSlipTypeApp();

    Xx03GetDefaultApproverVOImpl    vo  = getXx03GetDefaultApproverVO1();
    Xx03GetDefaultApproverVORowImpl row = null;
    vo.initQuery(slipTypeApp);

    // デフォルトの承認者が存在しない 
    if (vo.getRowCount() == 0)
    {
      changeFlag = true;
    }
    else
    {
      vo.first();
      row = (Xx03GetDefaultApproverVORowImpl)vo.getCurrentRow();
    }

    Xx03ConfirmUpdSlipsVOImpl    uVo  = getXx03ConfirmUpdSlipsVO1();
    Xx03ConfirmUpdSlipsVORowImpl uRow = null;
    uVo.first();
    uRow = (Xx03ConfirmUpdSlipsVORowImpl)uVo.getCurrentRow();


    // VOから承認者を取得した場合 
    if (!changeFlag)
    {
      uRow.setApproverPersonId(row.getSupervisorId());
      uRow.setApproverPersonName(row.getApproverCol());
    }
    else
    {
      uRow.setApproverPersonId(null);
      uRow.setApproverPersonName("");
    }
  }
  //ver 11.5.10.1.6I Add End


  //Ver11.5.10.1.6M Add Start
  /**
   * 空行を削除する。
   */
  private void removeEmptyRows() 
  {
    OAViewObject lineVO = getXx03ReceivableSlipsLineVO1();    
    RowSetIterator it=lineVO.createRowSetIterator("iterator");

    try
    {
      Xx03ReceivableSlipsLineVORowImpl row;
      while(null!=(row=(Xx03ReceivableSlipsLineVORowImpl)it.next())) 
      {
        if(!row.isInput())
        {
          // 空行は削除。
          row.remove();
        }
      }
    }
    finally
    {
      it.closeRowSetIterator();
    }
  }
  //Ver11.5.10.1.6M Add End

  /**
   * 
   * Container's getter for Xx03GetTransTypeNameVO1
   */
  public Xx03GetTransTypeNameVOImpl getXx03GetTransTypeNameVO1()
  {
    return (Xx03GetTransTypeNameVOImpl)findViewObject("Xx03GetTransTypeNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetArCustomerNameVO1
   */
  public Xx03GetArCustomerNameVOImpl getXx03GetArCustomerNameVO1()
  {
    return (Xx03GetArCustomerNameVOImpl)findViewObject("Xx03GetArCustomerNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetArCustSiteNameVO1
   */
  public Xx03GetArCustSiteNameVOImpl getXx03GetArCustSiteNameVO1()
  {
    return (Xx03GetArCustSiteNameVOImpl)findViewObject("Xx03GetArCustSiteNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetReceiptMethodNameVO1
   */
  public Xx03GetReceiptMethodNameVOImpl getXx03GetReceiptMethodNameVO1()
  {
    return (Xx03GetReceiptMethodNameVOImpl)findViewObject("Xx03GetReceiptMethodNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetTermsNameVO1
   */
  public Xx03GetTermsNameVOImpl getXx03GetTermsNameVO1()
  {
    return (Xx03GetTermsNameVOImpl)findViewObject("Xx03GetTermsNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetArLinesNameVO1
   */
  public Xx03GetArLinesNameVOImpl getXx03GetArLinesNameVO1()
  {
    return (Xx03GetArLinesNameVOImpl)findViewObject("Xx03GetArLinesNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetUomCodeVO1
   */
  public Xx03GetUomCodeVOImpl getXx03GetUomCodeVO1()
  {
    return (Xx03GetUomCodeVOImpl)findViewObject("Xx03GetUomCodeVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetCurrencyNameVO1
   */
  public Xx03GetCurrencyNameVOImpl getXx03GetCurrencyNameVO1()
  {
    return (Xx03GetCurrencyNameVOImpl)findViewObject("Xx03GetCurrencyNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03EnableSlipTypeVO1
   */
  public Xx03EnableSlipTypeVOImpl getXx03EnableSlipTypeVO1()
  {
    return (Xx03EnableSlipTypeVOImpl)findViewObject("Xx03EnableSlipTypeVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetTaxColVO1
   */
  public Xx03GetTaxColVOImpl getXx03GetTaxColVO1()
  {
    return (Xx03GetTaxColVOImpl)findViewObject("Xx03GetTaxColVO1");
  }

  /**
   * 
   * Container's getter for Xx03SlipTypesLovVO1
   */
  public Xx03SlipTypesLovVOImpl getXx03SlipTypesLovVO1()
  {
    return (Xx03SlipTypesLovVOImpl)findViewObject("Xx03SlipTypesLovVO1");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsToSlipNameVL1
   */
  public ViewLinkImpl getXx03ReceivableSlipsToSlipNameVL1()
  {
    return (ViewLinkImpl)findViewLink("Xx03ReceivableSlipsToSlipNameVL1");
  }

  /**
   * 
   * Container's getter for Xx03GetDefaultApproverVO1
   */
  public Xx03GetDefaultApproverVOImpl getXx03GetDefaultApproverVO1()
  {
    return (Xx03GetDefaultApproverVOImpl)findViewObject("Xx03GetDefaultApproverVO1");
  }

  /**
   * 
   * Container's getter for Xx03GetApproverNameVO1
   */
  public Xx03GetApproverNameVOImpl getXx03GetApproverNameVO1()
  {
    return (Xx03GetApproverNameVOImpl)findViewObject("Xx03GetApproverNameVO1");
  }

  /**
   * 
   * Container's getter for Xx03SlipTypesLovVO2
   */
  public Xx03SlipTypesLovVOImpl getXx03SlipTypesLovVO2()
  {
    return (Xx03SlipTypesLovVOImpl)findViewObject("Xx03SlipTypesLovVO2");
  }

  /**
   * 
   * Container's getter for Xx03ReceivableSlipsLineVO2
   */
  public Xx03ReceivableSlipsLineVOImpl getXx03ReceivableSlipsLineVO2()
  {
    return (Xx03ReceivableSlipsLineVOImpl)findViewObject("Xx03ReceivableSlipsLineVO2");
  }

  /**
   * 
   * Container's getter for Xx03GetArMenuSlipTypeVO1
   */
  public Xx03GetArMenuSlipTypeVOImpl getXx03GetArMenuSlipTypeVO1()
  {
    return (Xx03GetArMenuSlipTypeVOImpl)findViewObject("Xx03GetArMenuSlipTypeVO1");
  }

  /**
   * 
   * Container's getter for Xx03ChkUsrDepartmentVO1
   */
  public Xx03ChkUsrDepartmentVOImpl getXx03ChkUsrDepartmentVO1()
  {
    return (Xx03ChkUsrDepartmentVOImpl)findViewObject("Xx03ChkUsrDepartmentVO1");
  }

  //ver11.5.10.3 Add Start
  /**
   * 
   * Container's getter for Xx03ChkArCustomerVO1
   */
  public Xx03ChkArCustomerVOImpl Xx03ChkArCustomerVO1()
  {
    return (Xx03ChkArCustomerVOImpl)findViewObject("Xx03ChkArCustomerVO1");
  }
  //ver11.5.10.3 Add End

  //ver 11.5.10.2.6D Add Start
  /**
   *
   * 明細の存在チェック(存在しない場合エラー表示)
   */
  public void checkLineInput()
  {
    // 初期化処理
    String methodName = "checkLineInput";
    startProcedure(getClass().getName(), methodName);

    // 明細レコード存在フラグ
    boolean blnRowImp = false;

    // 明細用のイテレータ
    RowSetIterator selectIter = null;

    // 明細カウント
    int getRowCount;

    // 明細VO
    Xx03ReceivableSlipsLineVORowImpl lineRow = null;

    // ビュー・オブジェクトの取得
    Xx03ReceivableSlipsLineVOImpl lineVo = (Xx03ReceivableSlipsLineVOImpl)getXx03ReceivableSlipsLineVO1();

    // VOよりレコード数取得
    getRowCount = lineVo.getRowCount();
    
    // VOのカレントは動かさないようにイテレータを使用
    selectIter = lineVo.createRowSetIterator("selectIter");

    // イテレータ開放のためtry final使用
    try
    {
      // イテレータ設定
      selectIter.setRangeStart(0);
      selectIter.setRangeSize(getRowCount);
      
      // 明細のチェック
      for (int i=0; i<getRowCount; i++)
      {
        // VOよりRowの取得
        lineRow = (Xx03ReceivableSlipsLineVORowImpl)selectIter.getRowAtRangeIndex(i);
        if (lineRow != null)
        {
          // 入力チェックメソッドを呼び出してチェック
          if (lineRow.isInput())
          {
            // フラグをTrueとしループ終了
            blnRowImp = true;
            i = getRowCount;
          }
        }
      }

      // レコードが存在しない場合エラー
      if (blnRowImp == false)
      {
        // 明細無しエラー
        throw new OAException( "XX03"
                              ,"APP-XX03-13057"
                              ,null
                              ,OAException.ERROR
                              ,null);
      }
    } // try
    catch(OAException ex)
    {
      throw OAException.wrapperException(ex);
    }
    finally
    {
      selectIter.closeRowSetIterator();
    }

    // 終了処理
    endProcedure(getClass().getName(), methodName);
  } // checkLineInput()
  //ver 11.5.10.2.6D Add End

  //ver 11.5.10.2.6E Add Start
  /**
   * 重点管理を確認
   *
   * @return 重点管理の場合"Y"／異なる場合"N"
   */
  public String setAccAppFlag_Conf()
  {
    String retString = "";
    
    Xx03ConfirmDispSlipsVOImpl    dispVo  = getXx03ConfirmDispSlipsVO1();
    Xx03ConfirmDispSlipsVORowImpl dispRow = (Xx03ConfirmDispSlipsVORowImpl)dispVo.first();
    Xx03ConfirmUpdSlipsVOImpl     updVo   = getXx03ConfirmUpdSlipsVO1();
    Xx03ConfirmUpdSlipsVORowImpl  updRow  = (Xx03ConfirmUpdSlipsVORowImpl)updVo.first();

    if (!Xx03CommonUtil.STATUS_SAVE.equals(dispRow.getWfStatus()))
    {
      return updRow.getAccountApprovalFlag();
    }

    OADBTransaction txn = (OADBTransaction)getTransaction();

    // 実行SQLブロック
    CallableStatement state = txn.createCallableStatement(
      "begin XX03_DEPTINPUT_AR_CHECK_PKG.SET_ACCOUNT_APPROVAL_FLAG" +
      "(:1, :2, :3, :4, :5); end;", 0);

    try
    {
      Long l = new Long(dispRow.getReceivableId().longValue());
      long recIdLong = l.longValue();
      state.setLong(1, recIdLong);
      state.registerOutParameter(2, Types.VARCHAR);
      state.registerOutParameter(3, Types.VARCHAR);
      state.registerOutParameter(4, Types.VARCHAR);
      state.registerOutParameter(5, Types.VARCHAR);

      state.execute();
      String retFlag = state.getString(2);
      String retCode = state.getString(4);
      String retMesg = state.getString(5);
      state.close();

      // エラーはない
      if (retCode.equals("0"))
      {
        // 重点管理フラグのセット
        updRow.setAccountApprovalFlag(retFlag);
        getTransaction().commit();
        return retFlag;
      }
      return retString;
    }
    catch (SQLException sqlex)
    {
      throw new OAException(sqlex.getMessage());
    }
    finally
    {
      try
      {
        state.close();
      }
      catch (SQLException ex)
      {
        throw OAException.wrapperException(ex);
      }
    }
  }

  /**
   * 
   * Container's getter for XX03GetItemFormatVO1
   */
  public XX03GetItemFormatVOImpl getXX03GetItemFormatVO1()
  {
    return (XX03GetItemFormatVOImpl)findViewObject("XX03GetItemFormatVO1");
  }

  /**
   * 
   * Container's getter for Xx03ChkArCustomerVO1
   */
  public Xx03ChkArCustomerVOImpl getXx03ChkArCustomerVO1()
  {
    return (Xx03ChkArCustomerVOImpl)findViewObject("Xx03ChkArCustomerVO1");
  }

  //ver 11.5.10.2.6E Add End

}