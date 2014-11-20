/*============================================================================
* ファイル名 : XxwipInvestActualAMImpl
* 概要説明   : 投入実績入力アプリケーションモジュール
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-22 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;
import itoen.oracle.apps.xxwip.util.XxwipUtility;
import itoen.oracle.apps.xxwip.xxwip200002j.server.XxwipBatchHeaderVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

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
 * 投入実績入力アプリケーションモジュールクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxwipInvestActualAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipInvestActualAMImpl()
  {
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   * 
   * @param searchBatchId - バッチID
   * @param searchMtlDtlId - 生産原料詳細ID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void initialize(
    String searchBatchId,
    String searchMtlDtlId
  ) throws OAException
  {
    // 投入実績PVO取得
    XxwipInvestActualPVOImpl pvo = getXxwipInvestActualPVO1();
    if (pvo.getFetchedRowCount() == 0) 
    {
      pvo.setMaxFetchSize(0);
      pvo.executeQuery();
      pvo.insertRow(pvo.createRow());
      OARow row = (OARow)pvo.first();
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("GoBtnReject",              Boolean.TRUE);
      row.setAttribute("ChangeItemInvestReject",   Boolean.TRUE);
      row.setAttribute("ChangeItemReInvestReject", Boolean.TRUE);
      row.setAttribute("InvestItemNameReject",     Boolean.TRUE);
      row.setAttribute("ReInvestItemNameReject",   Boolean.TRUE);
      row.setAttribute("InvestMtlQtyReject",       Boolean.TRUE);
    }
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    // 検索を実行します。
    xbhvo.initQuery(searchBatchId);
    OARow row = (OARow)xbhvo.first();
    // 内外区分を取得し、自社の場合、委託加工単価、その他金額を無効にします。
    String inOutType = (String)row.getAttribute("InOutType");
    if (XxcmnUtility.isEquals(inOutType, XxwipConstants.IN_OUT_TYPE_ITAKU)) 
    {
      // 委託計算区分・委託加工単価を取得します。
      Date tranDate = null;
      if (XxcmnUtility.isBlankOrNull(row.getAttribute("ProductDate"))) 
      {
        // 生産予定日をセット
        tranDate = (Date)row.getAttribute("PlanDate");
      } else
      {
        // 生産日をセット
        tranDate = (Date)row.getAttribute("ProductDate");
      }
      // 委託先情報を取得します。
      HashMap retMap = XxwipUtility.getStockValue(
                         getOADBTransaction(),
                         (Number)row.getAttribute("ItemId"),
                         (String)row.getAttribute("OrgnCode"),
                         tranDate);
      // 加工単価が入力されている場合は、デフォルト値を設定しない。
      if (XxcmnUtility.isBlankOrNull(row.getAttribute("TrustProcessUnitPrice"))) 
      {
        row.setAttribute("TrustProcessUnitPrice", retMap.get("totalAmount"));
      }
      row.setAttribute("TrustCalculateType", retMap.get("calcType"));
      row.setAttribute("Trust", retMap.get("orgnName"));
    }
    // 投入実績PVO取得
    pvo = getXxwipInvestActualPVO1();
    OARow prow = (OARow)pvo.first();
    if (row != null) 
    {
      prow.setAttribute("GoBtnReject",              Boolean.FALSE);
      prow.setAttribute("ChangeItemInvestReject",   Boolean.FALSE);
      prow.setAttribute("ChangeItemReInvestReject", Boolean.FALSE);
      prow.setAttribute("InvestItemNameReject",     Boolean.FALSE);
      prow.setAttribute("ReInvestItemNameReject",   Boolean.FALSE);
    }
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("ProductDate"))) 
    {
      prow.setAttribute("GoBtnReject", Boolean.TRUE);
    } else
    {
      prow.setAttribute("GoBtnReject", Boolean.FALSE);
    }
    
    // 投入原料VOを作成します。
    XxwipItemChoiceInvestVOImpl xicivo = getXxwipItemChoiceInvestVO1();
    xicivo.initQuery(searchMtlDtlId);
    xicivo.first();
    int i = xicivo.getFetchedRowCount();
    if (xicivo.getFetchedRowCount() == 0) 
    {
      xicivo.setMaxFetchSize(0);
      xicivo.executeQuery();
      xicivo.insertRow(xicivo.createRow());
    }
    // 打込原料VOを作成します。
    XxwipItemChoiceReInvestVOImpl xicrivo = getXxwipItemChoiceReInvestVO1();
    xicrivo.initQuery(searchMtlDtlId);
    xicrivo.first();
    int a = xicrivo.getFetchedRowCount();
    if (xicrivo.getFetchedRowCount() == 0) 
    {
      xicrivo.setMaxFetchSize(0);
      xicrivo.executeQuery();
      xicrivo.insertRow(xicrivo.createRow());
    }
    // パラメータがNullの場合、エラーページへ遷移する
    if (XxcmnUtility.isBlankOrNull(searchBatchId)
     && XxcmnUtility.isBlankOrNull(searchMtlDtlId)) 
    {
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
    
    // 投入情報
    OARow xicivoRow = (OARow)xicivo.first();
    if ((xicivoRow != null) && (XxwipConstants.ITEM_TYPE_SHZ.equals(xicivoRow.getAttribute("ItemClassCode")))) 
    {
      prow.setAttribute("InvestMtlQtyReject", Boolean.FALSE);
    }
    xicivoRow.setAttribute("BatchId", new Number(Integer.parseInt(searchBatchId)));
    // 投入ロット情報VO取得
    XxwipInvestLotVOImpl xilvo = getXxwipInvestLotVO1();
    xilvo.initQuery(searchMtlDtlId);

    // 打込情報
    OARow xicrivoRow = (OARow)xicrivo.first();
    xicrivoRow.setAttribute("BatchId", new Number(Integer.parseInt(searchBatchId)));
    // 打込ロット情報VO取得
    XxwipReInvestLotVOImpl xrilvo = getXxwipReInvestLotVO1();
    xrilvo.initQuery(searchMtlDtlId);
  } // initialize

  /***************************************************************************
   * 品目変更処理を行うメソッドです。
   * 
   * @param searchMtlDtlId - 検索用生産原料詳細ID
   * @param tabType - タブタイプ 0:投入、1:打込
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doChange(
    String searchMtlDtlId,
    String tabType
  ) throws OAException
  {
    doCheck(tabType);
    // 投入情報タブの場合
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // 投入ロット情報VO取得
      XxwipInvestLotVOImpl vo = getXxwipInvestLotVO1();
      vo.initQuery(searchMtlDtlId);
      OARow row = (OARow)vo.first();
      if (row != null) 
      {
        // 投入実績PVO取得
        XxwipInvestActualPVOImpl pvo = getXxwipInvestActualPVO1();
        OARow prow = (OARow)pvo.first();
        if (XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))) 
        {
          prow.setAttribute("InvestMtlQtyReject", Boolean.FALSE);
        } else 
        {
          prow.setAttribute("InvestMtlQtyReject", Boolean.TRUE);
        }
      }
    // 打込情報タブの場合
    } else 
    {
      // 打込ロット情報VO取得
      XxwipReInvestLotVOImpl vo = getXxwipReInvestLotVO1();
      vo.initQuery(searchMtlDtlId);
    }
  } // doChange

  /***************************************************************************
   * 品目変更処理を行うメソッドです。
   * 
   * @param tabType - タブタイプ 0:投入、1:打込
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doCheck(
    String tabType
  ) throws OAException
  {
    OAViewObject vo = null;
    // 投入情報タブの場合
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // 投入LOV初期値保管用のVOを作成します。
      vo = getXxwipItemChoiceInvestVO1();
    // 打込情報タブの場合
    } else 
    {
      // 打込LOV初期値保管用のVOを作成します。
      vo = getXxwipItemChoiceReInvestVO1();
    }
    OARow row = (OARow)vo.first();
    // 品目コード
    Object itemNo = row.getAttribute("ItemNo");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(itemNo)) 
    {
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "ItemNo",
                  itemNo,
                  XxcmnConstants.APPL_XXWIP,         
                  XxwipConstants.XXWIP10058);
    }       
  } // doCheck

  /***************************************************************************
   * 適用処理を行うメソッドです。
   * @param tabType - タブタイプ　0：投入、1:打込
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String apply(
    String tabType
  ) throws OAException
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag  = false;
    boolean warnFlag = false;
    String  exeType  = XxcmnConstants.RETURN_NOT_EXE;

    // チェック処理
    doCheck(tabType);
    // 明細チェック処理
    checkDetail(tabType, exceptions);
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    getOADBTransaction().executeCommand("SAVEPOINT " + XxwipConstants.SAVE_POINT_XXWIP200001J);

    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    OARow  hdrRow  = (OARow)xbhvo.first();
    String batchId = String.valueOf(hdrRow.getAttribute("BatchId"));

    // ロック取得処理
    getRowLock(batchId);

    // 排他制御
    chkExclusiveControl();

    // 完成品の割当処理
    exeFlag = lineAllocation(tabType);

    // 処理が行われた場合
    if (exeFlag) 
    {

      // バッチセーブ
      XxwipUtility.saveBatch(getOADBTransaction(), batchId);

      // 在庫単価更新関数
      XxwipUtility.updateInvPrice(getOADBTransaction(), batchId);

      String inOutType = (String)hdrRow.getAttribute("InOutType");
      // 委託先の場合
      if (XxwipConstants.IN_OUT_TYPE_ITAKU.equals(inOutType)) 
      {
        // 委託加工費更新関数
        XxwipUtility.updateTrustPrice(getOADBTransaction(), batchId);
      }
    }
    // 処理正常終了
    if (exeFlag)
    {
      exeType = XxcmnConstants.RETURN_SUCCESS;
    } else 
    {
      exeType = XxcmnConstants.RETURN_NOT_EXE;
    }
    return exeType;
  } // apply

  /***************************************************************************
   * チェック処理を行うメソッドです。
   * @param tabType - タブタイプ　0：投入、1:打込
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void checkDetail(
    String tabType,
    ArrayList exceptions
  ) throws OAException 
  {
    String apiName  = "checkDetail";
    OAViewObject vo = null;
    OARow row       = null;
    boolean totalCheckFlag = true;

    // 投入情報タブ
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // 投入情報VO取得
      vo  = getXxwipInvestLotVO1();    
      // 更新行取得
      Row[] updRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((updRows != null) && (updRows.length > 0))
      {
        for (int i = 0; i < updRows.length; i++)
        {
          row = (OARow)updRows[i];
          totalCheckFlag = true;
          // 実績総数
          Object investedQty = row.getAttribute("InvestedQty");
          // 必須チェック
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "InvestedQty",
                                  investedQty,
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10058));
            totalCheckFlag = false;
          } else
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // 数量チェック
            } else if (!XxcmnUtility.chkCompareNumeric(2, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // 戻入総数
          Object returnQty = row.getAttribute("ReturnQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // 合計値チェック
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",","");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
          }
          // 製造不良総数
          Object mtlProdQty = row.getAttribute("MtlProdQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(mtlProdQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(mtlProdQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlProdQty",
                                    mtlProdQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // 業者不良総数
          Object mtlMfgQty = row.getAttribute("MtlMfgQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(mtlMfgQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(mtlMfgQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlMfgQty",
                                    mtlMfgQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // ロットステータスチェック
          Number lotId = (Number)row.getAttribute("LotId"); // ロットID
          if (!XxcmnUtility.isBlankOrNull(investedQty)
           && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
           && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,
                                  vo.getName(),
                                  row.getKey(),
                                  "LotNo",
                                  row.getAttribute("LotNo"),
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10081));
          }
        }
      }
      // 挿入行取得
      Row[] insRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_INS);
      if ((insRows != null) && (insRows.length > 0))
      {
        for (int i = 0; i < insRows.length; i++)
        {
          row = (OARow)insRows[i];
          totalCheckFlag = true;
          // 実績総数
          Object investedQty = row.getAttribute("InvestedQty");
          // 入力されている場合、チェックを行う。
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            totalCheckFlag = false;
          } else
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // 数量チェック
            } else if (!XxcmnUtility.chkCompareNumeric(2, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // 戻入総数
          Object returnQty = row.getAttribute("ReturnQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // 合計値チェック
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",","");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
          }
          // 製造不良総数
          Object mtlProdQty = row.getAttribute("MtlProdQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(mtlProdQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(mtlProdQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlProdQty",
                                    mtlProdQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // 業者不良総数
          Object mtlMfgQty = row.getAttribute("MtlMfgQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(mtlMfgQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(mtlMfgQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "MtlMfgQty",
                                    mtlMfgQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // ロットステータスチェック
          Number lotId = (Number)row.getAttribute("LotId"); // ロットID
          if (!XxcmnUtility.isBlankOrNull(investedQty)
           && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
           && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,
                                  vo.getName(),
                                  row.getKey(),
                                  "LotNo",
                                  row.getAttribute("LotNo"),
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10081));
          }
        }
      }
    // 打込情報タブ
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      // 打込情報VO取得
      vo  = getXxwipReInvestLotVO1();
      // 更新行取得
      Row[] updRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((updRows != null) && (updRows.length > 0))
      {
        for (int i = 0; i < updRows.length; i++)
        {
          row = (OARow)updRows[i];
          totalCheckFlag = true;
          // 実績総数
          Object investedQty = row.getAttribute("InvestedQty");
          // 必須チェック
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "InvestedQty",
                                  investedQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10058));
            totalCheckFlag = false;
          } else
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // 数量チェック
            } else if (!XxcmnUtility.chkCompareNumeric(2, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // 戻入総数
          Object returnQty = row.getAttribute("ReturnQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // 合計値チェック
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",", "");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
            // ロットステータスチェック
            Number lotId = (Number)row.getAttribute("LotId"); // ロットID
            if (!XxcmnUtility.isBlankOrNull(investedQty)
             && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
             && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,
                                    vo.getName(),
                                    row.getKey(),
                                    "LotNo",
                                    row.getAttribute("LotNo"),
                                    XxcmnConstants.APPL_XXWIP,
                                    XxwipConstants.XXWIP10081));
            }
          }
        }
      }
      // 挿入行取得
      Row[] insRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_INS);
      if ((insRows != null) && (insRows.length > 0))
      {
        for (int i = 0; i < insRows.length; i++)
        {
          row = (OARow)insRows[i];
          totalCheckFlag = true;
          // 実績総数
          Object investedQty = row.getAttribute("InvestedQty");
          // 入力されている場合、チェックを行う。
          if (XxcmnUtility.isBlankOrNull(investedQty))
          {
            totalCheckFlag = false;
          } else
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(investedQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              totalCheckFlag = false;
            // 数量チェック
            } else if (!XxcmnUtility.chkCompareNumeric(1, investedQty, XxcmnConstants.STRING_ZERO))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
              totalCheckFlag = false;
            }
          }
          // 戻入総数
          Object returnQty = row.getAttribute("ReturnQty");
          // 入力されている場合、チェックを行う。
          if (!XxcmnUtility.isBlankOrNull(returnQty))
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(returnQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ReturnQty",
                                    returnQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
              returnQty = XxcmnConstants.STRING_ZERO;
            }
          }
          // 合計値チェック
          if (totalCheckFlag) 
          {
            String actualQty = XxwipUtility.subtract(getOADBTransaction(), investedQty, returnQty);
            if (!XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)
             && !XxcmnUtility.chkCompareNumeric(1, actualQty,   XxcmnConstants.STRING_ZERO)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "InvestedQty",
                                    investedQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10064));
            } else 
            {
              String stockQty  = (String)row.getAttribute("StockQty");
              stockQty  = stockQty.replaceAll(",","");
              if (XxcmnUtility.chkCompareNumeric(1, actualQty, stockQty)) 
              {
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,
                                      vo.getName(),
                                      row.getKey(),
                                      "InvestedQty",
                                      investedQty,
                                      XxcmnConstants.APPL_XXWIP,
                                      XxwipConstants.XXWIP10065));
              }
            }
          }
          // ロットステータスチェック
          Number lotId = (Number)row.getAttribute("LotId"); // ロットID
          if (!XxcmnUtility.isBlankOrNull(investedQty)
           && !XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && !XxwipConstants.ITEM_TYPE_SHZ.equals(row.getAttribute("ItemClassCode"))
           && !XxwipUtility.checkLotStatus(getOADBTransaction(), lotId)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,
                                  vo.getName(),
                                  row.getKey(),
                                  "LotNo",
                                  row.getAttribute("LotNo"),
                                  XxcmnConstants.APPL_XXWIP,
                                  XxwipConstants.XXWIP10081));
          }
        }
      }
    }
  } // checkDetail

  /***************************************************************************
   * ロック処理を行うメソッドです。
   * @param batchId - バッチID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getRowLock(
    String batchId
  ) throws OAException 
  {
    String apiName = "getRowLock";
    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR gme_cur ");
    sb.append("  IS ");
    sb.append("    SELECT gbh.batch_id batch_id     "); // バッチID
    sb.append("    FROM   gme_batch_header      gbh "); // 生産バッチヘッダ
    sb.append("          ,gme_material_details  gmd "); // 生産原料詳細
    sb.append("          ,xxwip_material_detail xmd "); // 生産原料詳細アドオン
    sb.append("          ,ic_tran_pnd           itp "); // OPM保留在庫トランザクション
    sb.append("    WHERE  gbh.batch_id           = gmd.batch_id           ");
    sb.append("    AND    gmd.material_detail_id = itp.line_id            ");
    sb.append("    AND    gmd.material_detail_id = xmd.material_detail_id ");
    sb.append("    AND    gbh.batch_id           = TO_NUMBER(:1)          ");
    sb.append("    FOR UPDATE OF gbh.batch_id");
    sb.append("                 ,gmd.batch_id");
    sb.append("                 ,xmd.batch_id");
    sb.append("                 ,itp.doc_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  gme_cur; ");
    sb.append("  CLOSE gme_cur; ");
    sb.append("END; ");

    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      //PL/SQLを実行します
      int i = 1;
      cstmt.setString(i++, batchId);
      
      cstmt.execute();

    } catch (SQLException s) 
    {
      // ロールバック
      XxwipUtility.rollBack(getOADBTransaction(),
                            XxwipConstants.SAVE_POINT_XXWIP200001J);
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ロックエラー
      throw new OAException(XxcmnConstants.APPL_XXWIP, 
                            XxwipConstants.XXWIP10014);
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
        XxwipUtility.rollBack(getOADBTransaction(), 
                              XxwipConstants.SAVE_POINT_XXWIP200001J);
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getRowLock

  /***************************************************************************
   * 排他制御チェックを行うメソッドです。
   ***************************************************************************
   */
  public void chkExclusiveControl()
  {
    String apiName  = "chkExclusiveControl";
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(xmd.batch_id) cnt "); // バッチID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   xxwip_material_detail xmd    "); // 生産原料詳細アドオン
      sb.append("  WHERE  xmd.mtl_detail_addon_id = :2 "); // 生産原料詳細アドオンID
      sb.append("  AND    TO_CHAR(xmd.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      // 投入情報
      vo  = getXxwipInvestLotVO1();
      row = (OARow)vo.first();
      Number mtlDtlAddOnId     = null; 
      String xmdLastUpdateDate = null; 
      int fetchedRowCount = vo.getFetchedRowCount();
      int i = 1;
      // 更新行取得
      Row[] rows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // 各種情報を取得します。
          mtlDtlAddOnId     = (Number)row.getAttribute("MtlDetailAddonId");// 生産原料詳細ID 
          xmdLastUpdateDate = (String)row.getAttribute("XmdLastUpdateDate"); // 最終更新日
          //PL/SQLを実行します
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlAddOnId));
          cstmt.setString(i++, xmdLastUpdateDate);
      
          cstmt.execute();
          // 排他エラーの場合
          if (cstmt.getInt(1) == 0) 
          {
            doRollBack();
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10147);
          }
        }
      }
      // 打込情報
      vo  = getXxwipReInvestLotVO1();
      row = (OARow)vo.first();
      fetchedRowCount = vo.getFetchedRowCount();
      // 更新行取得
      rows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // 各種情報を取得します。
          mtlDtlAddOnId     = (Number)row.getAttribute("MtlDetailAddonId");  // 生産原料詳細ID 
          xmdLastUpdateDate = (String)row.getAttribute("XmdLastUpdateDate"); // 最終更新日
          //PL/SQLを実行します
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlAddOnId));
          cstmt.setString(i++, xmdLastUpdateDate);
          cstmt.execute();
          // 排他エラーの場合
          if (cstmt.getInt(1) == 0) 
          {
            doRollBack();
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10147);
          }
        }
      }
    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                              XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkEexclusiveControl

  /*****************************************************************************
   * 割当の登録・更新を行います。
   * @param tabType - タブタイプ　0：投入、1：打込
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public boolean lineAllocation(
    String tabType
  ) throws OAException 
  {

    String apiName  = "lineAllocation";
    OAViewObject vo = null;
    // 処理フラグ
    boolean exeFlag = false;
    // ヘッダ情報を取得します。
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // 各種情報を取得します。
    Date   productDate = (Date)hdrRow.getAttribute("ProductDate");        // 生産日
    String location    = (String)hdrRow.getAttribute("DeliveryLocation"); // 納品場所
    String whseCode    = (String)hdrRow.getAttribute("WipWhseCode");      // 倉庫コード
    Number batchId     = (Number)hdrRow.getAttribute("BatchId");          // バッチID

    // 投入情報タブの場合
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType))
    {
      // 投入ロット情報を取得します。
      vo  = getXxwipInvestLotVO1();
    // 打込情報タブの場合
    } else
    {
      // 打込ロット情報を取得します。
      vo  = getXxwipReInvestLotVO1();
    }

    /****************************************
     * 挿入処理
     *****************************************/
    // 挿入用のPL/SQLの作成を行います
    StringBuffer insSb = new StringBuffer(1000);
    insSb.append("BEGIN ");
    insSb.append("  INSERT INTO xxwip_material_detail( ");// 生産原料詳細アドオン
    insSb.append("    mtl_detail_addon_id    ");// 生産原料詳細アドオンID
    insSb.append("   ,batch_id               ");// バッチID
    insSb.append("   ,material_detail_id     ");// 生産原料詳細ID
    insSb.append("   ,item_id                ");// 品目ID
    insSb.append("   ,lot_id                 ");// ロットID
    insSb.append("   ,instructions_qty       ");// 指示総数
    insSb.append("   ,invested_qty           ");// 投入数量
    insSb.append("   ,return_qty             ");// 戻入数量
    insSb.append("   ,mtl_prod_qty           ");// 資材製造不良数
    insSb.append("   ,mtl_mfg_qty            ");// 資材業者不良数
    insSb.append("   ,location_code          ");// 手配倉庫コード
    insSb.append("   ,plan_type              ");// 予定区分
    insSb.append("   ,plan_number            ");// 番号
    insSb.append("   ,created_by             ");// 作成者
    insSb.append("   ,creation_date          ");// 作成日
    insSb.append("   ,last_updated_by        ");// 最終更新者
    insSb.append("   ,last_update_date       ");// 最終更新日
    insSb.append("   ,last_update_login      ");// 最終更新ログイン
    insSb.append("   ,request_id             ");// 要求ID
    insSb.append("   ,program_application_id ");// コンカレント・プログラム・アプリケーションID
    insSb.append("   ,program_id             ");// コンカレント・プログラムID
    insSb.append("   ,program_update_date    ");// プログラム更新日
    insSb.append("  ) VALUES ( ");
    insSb.append("    xxwip_mtl_detail_addon_id_s1.NEXTVAL ");// 生産原料詳細アドオンID
    insSb.append("   ,:1                  ");// バッチID
    insSb.append("   ,:2                  ");// 生産原料詳細ID
    insSb.append("   ,:3                  ");// 品目ID
    insSb.append("   ,:4                  ");// ロットID
    insSb.append("   ,null                ");// 指示総数
    insSb.append("   ,:5                  ");// 投入数量
    insSb.append("   ,NVL(:6, 0)          ");// 戻入数量
    insSb.append("   ,NVL(:7, 0)          ");// 資材製造不良数
    insSb.append("   ,NVL(:8, 0)          ");// 資材業者不良数
    insSb.append("   ,:9                  ");// 手配倉庫コード
    insSb.append("   ,'4'                 ");// 予定区分
    insSb.append("   ,NULL                ");// 番号
    insSb.append("   ,fnd_global.user_id  ");// 作成者
    insSb.append("   ,SYSDATE             ");// 作成日
    insSb.append("   ,fnd_global.user_id  ");// 最終更新者
    insSb.append("   ,SYSDATE             ");// 最終更新日
    insSb.append("   ,fnd_global.login_id ");// 最終更新ログイン
    insSb.append("   ,NULL                ");// 要求ID
    insSb.append("   ,NULL                ");// コンカレント・プログラム・アプリケーションID
    insSb.append("   ,NULL                ");// コンカレント・プログラムID
    insSb.append("   ,NULL                ");// プログラム更新日
    insSb.append("  ); ");
    insSb.append("  :10 := TO_CHAR(TO_NUMBER(:11) - TO_NUMBER(NVL(:12, 0))); ");
    insSb.append("END; ");
    // 挿入行取得
    Row[] insRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_INS);
    if ((insRows != null) && (insRows.length > 0))
    {
      //PL/SQLの設定を行います
      CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                  insSb.toString(),
                                  OADBTransaction.DEFAULT);
      String actualQty = null;
      OARow  row       = null;
      for (int i = 0; i < insRows.length; i++)
      {
        row = (OARow)insRows[i];
        String investedQty = (String)row.getAttribute("InvestedQty");    // 実績数量
        if (!XxcmnUtility.isBlankOrNull(investedQty)) 
        {
          Number mtlDtlId      = (Number)row.getAttribute("MaterialDetailId");   // 生産原料詳細ID   
          Number movLotDtlId   = (Number)row.getAttribute("MovLotDtlId");        // 移動ロット詳細詳細ID   
          String xmldActualQty = (String)row.getAttribute("XmldActualQuantity"); // 移動ロット詳細実績数量   
          String itemType      = (String)row.getAttribute("ItemClassCode");      // 品目タイプ
          Number itemId        = (Number)row.getAttribute("ItemId");             // 品目ID
          String itemNo        = (String)row.getAttribute("ItemNo");             // 品目コード
          Number lotId         = (Number)row.getAttribute("LotId");              // ロットID
          String lotNo         = (String)row.getAttribute("LotNo");              // ロットNo
          String returnQty     = (String)row.getAttribute("ReturnQty");          // 戻入数量
          String mtlProdQty    = XxcmnConstants.STRING_ZERO;                     // 製造不良総数
          String mtlMfgQty     = XxcmnConstants.STRING_ZERO;                     // 業者不良総数
          if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType))
          {
            mtlProdQty = (String)row.getAttribute("MtlProdQty");     // 製造不良総数
            mtlMfgQty  = (String)row.getAttribute("MtlMfgQty");      // 業者不良総数
          }
          try
          {
            //PL/SQLを実行します
            int x = 1;
            cstmt.setInt(x++, XxcmnUtility.intValue(batchId));
            cstmt.setInt(x++, XxcmnUtility.intValue(mtlDtlId));
            cstmt.setInt(x++, XxcmnUtility.intValue(itemId));
            cstmt.setInt(x++, XxcmnUtility.intValue(lotId));
            cstmt.setString(x++, investedQty);
            cstmt.setString(x++, returnQty);
            cstmt.setString(x++, mtlProdQty);
            cstmt.setString(x++, mtlMfgQty);
            cstmt.setString(x++, location);
            cstmt.registerOutParameter(x++, Types.NUMERIC); 
            cstmt.setString(x++, investedQty);
            cstmt.setString(x++, returnQty);

            // 生産原料詳細アドオンに行を追加します。
            cstmt.execute();
            actualQty = cstmt.getString(10);
            exeFlag = true;
          } catch (SQLException s) 
          {
            // ロールバック
            XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
            XxcmnUtility.writeLog(getOADBTransaction(),
                                  XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
              // ロールバック
              XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
              XxcmnUtility.writeLog(getOADBTransaction(),
                                    XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                                    s.toString(),
                                    6);
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxcmnConstants.XXCMN10123);
            } 
          }

          // 引数を設定します。
          HashMap params = new HashMap();
          params.put("batchId",      batchId);
          params.put("itemId",       itemId);
          params.put("itemNo",       itemNo);
          params.put("lotNo",        lotNo);
          params.put("lotId",        lotId);
          params.put("mtlDtlId",     mtlDtlId);
          params.put("movLotDtlId",  movLotDtlId);
          params.put("actualQty",    actualQty);
          params.put("xmldActualQty",xmldActualQty);
          params.put("location",     location);
          params.put("whseCode",     whseCode);
          params.put("productDate",  productDate);
           
          // 割当追加APIを実行します。
          XxwipUtility.insertLineAllocation(
            getOADBTransaction(),
            params,
            XxwipConstants.LINE_TYPE_INVEST);
          // 移動ロット詳細への書込み処理を行います。
          XxwipUtility.movLotExecute(
            getOADBTransaction(),
            params);
        }
      }        
    }

    // 更新用のPL/SQLの作成を行います
    StringBuffer updSb = new StringBuffer(1000);
    updSb.append("BEGIN ");
    updSb.append("  UPDATE xxwip_material_detail xmd "); // 生産原料詳細アドオン
    updSb.append("  SET    xmd.invested_qty      = :1 "); // 実績総数
    updSb.append("        ,xmd.return_qty        = :2 "); // 戻入総数
    updSb.append("        ,xmd.mtl_prod_qty      = :3 "); // 製造不良総数
    updSb.append("        ,xmd.mtl_mfg_qty       = :4 "); // 業者不良総数
    updSb.append("        ,xmd.last_updated_by   = fnd_global.user_id "); // 最終更新者
    updSb.append("        ,xmd.last_update_date  = SYSDATE ");            // 最終更新日
    updSb.append("        ,xmd.last_update_login = fnd_global.login_id "); // 最終更新ログイン
    updSb.append("  WHERE  xmd.mtl_detail_addon_id = :5 ; ");
    updSb.append("  :6 := TO_CHAR(TO_NUMBER(:7) - TO_NUMBER(NVL(:8, 0))); ");
    updSb.append("END; ");

    // 削除用のPL/SQLの作成を行います
    StringBuffer delSb = new StringBuffer(1000);
    delSb.append("BEGIN ");
    delSb.append("  DELETE xxwip_material_detail xmd ");      // 生産原料詳細アドオン
    delSb.append("  WHERE  xmd.mtl_detail_addon_id  = :1; "); 
    delSb.append("END; ");

    // 更新行取得
    Row[] updRows = vo.getFilteredRows("RecordType", XxwipConstants.RECORD_TYPE_UPD);
    if ((updRows != null) && (updRows.length > 0))
    {
      String actualQty = null;
      OARow  row       = null;
      for (int i = 0; i < updRows.length; i++)
      {
        row = (OARow)updRows[i];
        String instructionsQty = (String)row.getAttribute("InstructionsQty"); // 指示数量
        String investedQty     = (String)row.getAttribute("InvestedQty");     // 実績数量
        String returnQty       = (String)row.getAttribute("ReturnQty");       // 戻入数量
        String baseInvestedQty = (String)row.getAttribute("BaseInvestedQty"); // 元実績数量
        String baseReturnQty   = (String)row.getAttribute("BaseReturnQty");   // 元戻入数量
        String mtlProdQty      = XxcmnConstants.STRING_ZERO;     // 製造不良総数
        String mtlMfgQty       = XxcmnConstants.STRING_ZERO;     // 業者不良総数
        String baseMtlProdQty  = XxcmnConstants.STRING_ZERO;     // 元製造不良総数
        String baseMtlMfgQty   = XxcmnConstants.STRING_ZERO;     // 元業者不良総数
        if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType))
        {
          mtlProdQty     = (String)row.getAttribute("MtlProdQty");     // 製造不良総数
          mtlMfgQty      = (String)row.getAttribute("MtlMfgQty");      // 業者不良総数
          baseMtlProdQty = (String)row.getAttribute("BaseMtlProdQty");     // 元製造不良総数
          baseMtlMfgQty  = (String)row.getAttribute("BaseMtlMfgQty");      // 元業者不良総数
        }
        // 戻入総数がNullの場合
        if (XxcmnUtility.isBlankOrNull(returnQty)) 
        {
           returnQty = XxcmnConstants.STRING_ZERO; 
        }
        // 製造不良総数がNullの場合
        if (XxcmnUtility.isBlankOrNull(mtlProdQty)) 
        {
           mtlProdQty = XxcmnConstants.STRING_ZERO; 
        }
        // 業者不良総数がNullの場合
        if (XxcmnUtility.isBlankOrNull(mtlMfgQty)) 
        {
           mtlMfgQty = XxcmnConstants.STRING_ZERO; 
        }
        // 実績総数がNullではない場合        
        if (!XxcmnUtility.isBlankOrNull(investedQty)) 
        {
          Number mtlDtlId    = (Number)row.getAttribute("MaterialDetailId"); // 生産原料詳細ID   
          Number mtlAddonId  = (Number)row.getAttribute("MtlDetailAddonId"); // 生産原料詳細アドオンID   
          Number transId     = (Number)row.getAttribute("TransId");          // トランザクションID
          Number itemId      = (Number)row.getAttribute("ItemId");           // 品目ID
          String itemType    = (String)row.getAttribute("ItemClassCode");    // 品目タイプ
          Number lotId       = (Number)row.getAttribute("LotId");            // ロットID
          Number movLotDtlId = (Number)row.getAttribute("MovLotDtlId");      // 移動ロット詳細詳細ID   
          String xmldActualQuantity = (String)row.getAttribute("XmldActualQuantity"); // 移動ロット詳細実績数量   
          String itemNo      = (String)row.getAttribute("ItemNo");           // 品目コード
          String lotNo       = (String)row.getAttribute("LotNo");            // ロットNo
          // 引数を設定します。
          HashMap params = new HashMap();
          params.put("batchId",     batchId);
          params.put("mtlDtlId",    mtlDtlId);
          params.put("transId",     transId);
          params.put("movLotDtlId", movLotDtlId);
          params.put("itemId",      itemId);
          params.put("itemNo",      itemNo);
          params.put("lotId",       lotId);
          params.put("lotNo",       lotNo);
          params.put("xmldActualQuantity",   xmldActualQuantity);
          params.put("location",    location);
          params.put("productDate", productDate);
           
          // 指示数量が0以外で、実績数量、戻入数量に0が入力された場合
          if (XxcmnUtility.isBlankOrNull(instructionsQty)
           && XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
           && XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)) 
          {
            /****************************************
             * 削除処理
             *****************************************/
            //PL/SQLの設定を行います
            CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                        delSb.toString(),
                                        OADBTransaction.DEFAULT);
            try
            {
              //PL/SQLを実行します
              int x = 1;
              cstmt.setInt(x++, XxcmnUtility.intValue(mtlAddonId));

              // 生産原料詳細アドオンの行を更新します。
              cstmt.execute();
              actualQty = XxcmnConstants.STRING_ZERO;
              params.put("actualQty",   actualQty);
              exeFlag = true;

              // 割当削除APIを実行します。
              XxwipUtility.deleteLineAllocation(
                getOADBTransaction(),
                params,
                XxwipConstants.LINE_TYPE_INVEST);
              // 移動ロット詳細への書込み処理を行います。
              XxwipUtility.movLotExecute(
                getOADBTransaction(),
                params);
            } catch (SQLException s) 
            {
              // ロールバック
              XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
              XxcmnUtility.writeLog(getOADBTransaction(),
                                    XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                // ロールバック
                XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
                XxcmnUtility.writeLog(getOADBTransaction(),
                                      XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                                      s.toString(),
                                      6);
                throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                      XxcmnConstants.XXCMN10123);
              } 
            }
          // 数量が変更された場合
          }else if (!XxcmnUtility.chkCompareNumeric(3, investedQty, baseInvestedQty)
                 || !XxcmnUtility.chkCompareNumeric(3, returnQty,   baseReturnQty)
                 || !XxcmnUtility.chkCompareNumeric(3, mtlProdQty,  baseMtlProdQty)
                 || !XxcmnUtility.chkCompareNumeric(3, mtlMfgQty,   baseMtlMfgQty)) 
          {
            /****************************************
             * 更新処理
             *****************************************/
            //PL/SQLの設定を行います
            CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                        updSb.toString(),
                                        OADBTransaction.DEFAULT);
            try
            {
              //PL/SQLを実行します
              int x = 1;
              cstmt.setString(x++, investedQty);
              cstmt.setString(x++, returnQty);
              cstmt.setString(x++, mtlProdQty);
              cstmt.setString(x++, mtlMfgQty);
              cstmt.setInt(x++, XxcmnUtility.intValue(mtlAddonId));
              cstmt.registerOutParameter(x++, Types.NUMERIC); 
              cstmt.setString(x++, investedQty);
              cstmt.setString(x++, returnQty);

              // 生産原料詳細アドオンの行を更新します。
              cstmt.execute();
              actualQty = cstmt.getString(6);
              params.put("actualQty",    actualQty);
              // 指示総数がNull以外の場合、削除では無く更新。
              if (!XxcmnUtility.isBlankOrNull(instructionsQty)
               &&  XxcmnUtility.chkCompareNumeric(3, investedQty, XxcmnConstants.STRING_ZERO)
               &&  XxcmnUtility.chkCompareNumeric(3, returnQty,   XxcmnConstants.STRING_ZERO)) 
              {
                params.put("completedInd", XxcmnConstants.STRING_ZERO);
                params.put("actualQty",    instructionsQty.replaceAll(",", ""));
              }
              exeFlag = true;

              // 割当更新APIを実行します。
              XxwipUtility.updateLineAllocation(
                getOADBTransaction(),
                params,
                XxwipConstants.LINE_TYPE_INVEST);
              // 移動ロット詳細への書込み処理を行います。
              XxwipUtility.movLotExecute(
                getOADBTransaction(),
                params);
            } catch (SQLException s) 
            {
              // ロールバック
              XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
              XxcmnUtility.writeLog(getOADBTransaction(),
                                    XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
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
                // ロールバック
                XxwipUtility.rollBack(getOADBTransaction(), XxwipConstants.SAVE_POINT_XXWIP200001J);
                XxcmnUtility.writeLog(getOADBTransaction(),
                                      XxwipConstants.CLASS_AM_XXWIP200002J + XxcmnConstants.DOT + apiName,
                                      s.toString(),
                                      6);
                throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                      XxcmnConstants.XXCMN10123);
              } 
            }
          }
        }
      }        
    }
    return exeFlag;
  } // lineAllocation

  /***************************************************************************
   * コミット処理を行うメソッドです。
   * @param batchId - バッチID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doCommit(
    String batchId,
    String mtlDtlId,
    String tabType
  ) throws OAException
  {
    // コミット
    getOADBTransaction().commit();
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    // 検索を実行します。
    xbhvo.initQuery(batchId);
    OARow row = (OARow)xbhvo.first();
    // 内外区分を取得し、自社の場合、委託加工単価、その他金額を無効にします。
    String inOutType = (String)row.getAttribute("InOutType");
    if (XxcmnUtility.isEquals(inOutType, XxwipConstants.IN_OUT_TYPE_ITAKU)) 
    {
      // 委託計算区分・委託加工単価を取得します。
      Date tranDate = null;
      if (XxcmnUtility.isBlankOrNull(row.getAttribute("ProductDate"))) 
      {
        // 生産予定日をセット
        tranDate = (Date)row.getAttribute("PlanDate");
      } else
      {
        // 生産日をセット
        tranDate = (Date)row.getAttribute("ProductDate");
      }
      // 委託先情報を取得します。
      HashMap retMap = XxwipUtility.getStockValue(
                         getOADBTransaction(),
                         (Number)row.getAttribute("ItemId"),
                         (String)row.getAttribute("OrgnCode"),
                         tranDate);
      // 加工単価が入力されている場合は、デフォルト値を設定しない。
      if (XxcmnUtility.isBlankOrNull(row.getAttribute("TrustProcessUnitPrice"))) 
      {
        row.setAttribute("TrustProcessUnitPrice", retMap.get("totalAmount"));
      }
      row.setAttribute("TrustCalculateType", retMap.get("calcType"));
      row.setAttribute("Trust", retMap.get("orgnName"));
    }
    // 再検索
    doChange(mtlDtlId, tabType);
    // 登録完了メッセージ
    throw new OAException(
      XxcmnConstants.APPL_XXWIP,
      XxwipConstants.XXWIP30001, 
      null, 
      OAException.INFORMATION, 
      null);
  } // doCommit

  /***************************************************************************
   * ロールバック処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doRollBack()
  {
    // セーブポイントまでロールバックし、コミット
    XxwipUtility.rollBack(getOADBTransaction(),
                          XxwipConstants.SAVE_POINT_XXWIP200001J);
  } // doRollBack

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxwip.xxwip200002j.server", "XxwipInvestActualAMLocal");
  }

  /**
   * 
   * Container's getter for TypeVO1
   */
  public OAViewObjectImpl getTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("TypeVO1");
  }


  /**
   * 
   * Container's getter for XxwipInvestLotVO1
   */
  public XxwipInvestLotVOImpl getXxwipInvestLotVO1()
  {
    return (XxwipInvestLotVOImpl)findViewObject("XxwipInvestLotVO1");
  }

  /**
   * 
   * Container's getter for XxwipInvestActualPVO1
   */
  public XxwipInvestActualPVOImpl getXxwipInvestActualPVO1()
  {
    return (XxwipInvestActualPVOImpl)findViewObject("XxwipInvestActualPVO1");
  }

  /**
   * 
   * Container's getter for XxwipReInvestLotVO1
   */
  public XxwipReInvestLotVOImpl getXxwipReInvestLotVO1()
  {
    return (XxwipReInvestLotVOImpl)findViewObject("XxwipReInvestLotVO1");
  }

  /**
   * 
   * Container's getter for XxwipItemChoiceInvestVO1
   */
  public XxwipItemChoiceInvestVOImpl getXxwipItemChoiceInvestVO1()
  {
    return (XxwipItemChoiceInvestVOImpl)findViewObject("XxwipItemChoiceInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipItemChoiceReInvestVO1
   */
  public XxwipItemChoiceReInvestVOImpl getXxwipItemChoiceReInvestVO1()
  {
    return (XxwipItemChoiceReInvestVOImpl)findViewObject("XxwipItemChoiceReInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchHeaderVO1
   */
  public XxwipBatchHeaderVOImpl getXxwipBatchHeaderVO1()
  {
    return (XxwipBatchHeaderVOImpl)findViewObject("XxwipBatchHeaderVO1");
  }
}