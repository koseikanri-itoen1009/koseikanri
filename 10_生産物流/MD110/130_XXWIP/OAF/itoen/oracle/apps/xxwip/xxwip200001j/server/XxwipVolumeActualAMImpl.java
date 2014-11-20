/*============================================================================
* ファイル名 : XxwipVolumeActualAMImpl
* 概要説明   : 出来高実績入力アプリケーションモジュール
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  二瓶大輔     新規作成
* 2008-05-12      二瓶大輔     変更要求対応(#75)
* 2008-06-12 1.1  二瓶大輔     ST不具合対応(#78)
* 2008-06-27 1.2  二瓶大輔     結合テスト指摘対応
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwip.poplist.server.SlitVOImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;
import itoen.oracle.apps.xxwip.util.XxwipUtility;
import itoen.oracle.apps.xxwip.xxwip200001j.server.XxwipBatchHeaderVOImpl;
import itoen.oracle.apps.xxwip.xxwip200001j.server.XxwipBatchInvestVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OARowValException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 出来高実績入力画面のアプリケーションモジュールクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.2
 ***************************************************************************
 */
public class XxwipVolumeActualAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipVolumeActualAMImpl()
  {
  }
  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("oracle.apps.fnd.framework.itoenprj.test.server", "XxwipVolumeActualAMLocal");
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   ***************************************************************************
   */
  public void initialize()
  {
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl vo = getXxwipBatchHeaderVO1();
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setWhereClauseParam(0,null);
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setNewRowState(Row.STATUS_INITIALIZED);
    }
    // 出来高実績PVO取得
    XxwipVolumeActualPVOImpl pvo = getXxwipVolumeActualPVO1();
    if (pvo.getFetchedRowCount() == 0) 
    {
      pvo.setMaxFetchSize(0);
      pvo.executeQuery();
      pvo.insertRow(pvo.createRow());
      OARow row = (OARow)pvo.first();
      row.setAttribute("RowKey", new Number(1));
      // レンダリング制御
      handleVolumeActualEvent(
        XxcmnConstants.STRING_TRUE, 
        XxcmnConstants.STRING_FALSE, 
        XxcmnConstants.STRING_FALSE, 
        XxcmnConstants.STRING_FALSE,
        XxcmnConstants.STRING_TRUE,
        XxcmnConstants.STRING_TRUE,
        XxcmnConstants.STRING_NO);
    }
  } // initialize

  /***************************************************************************
   * ロット明細ボタン押下時の処理を行うメソッドです。
   * @param tabType - タブタイプ　0：投入、1：打込
   * @return HashMap パラメータ群
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap doDetail(String tabType)
  {
    OARow row = null;
    OAViewObject vo = null;
    Number batchId  = null;
    Number mtlDtlId = null;
    //パラメータ用HashMap生成
    HashMap pageParams = new HashMap();
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // 投入情報VO取得
      vo = getXxwipBatchInvestVO1();
    } else
    {
      // 打込情報VO取得
      vo = getXxwipBatchReInvestVO1();
    }
    // 挿入行取得
    row = (OARow)vo.getFirstFilteredRow("SelectFlag", XxcmnConstants.STRING_Y);
    batchId  = (Number)row.getAttribute("BatchId");
    mtlDtlId = (Number)row.getAttribute("MaterialDetailId");
    if (XxcmnUtility.isBlankOrNull(mtlDtlId)) 
    {
      throw new OARowValException(         
                  OAAttrValException.TYP_VIEW_OBJECT,
                  vo.getName(),
                  row.getKey(),
                  XxcmnConstants.APPL_XXWIP,
                  XxwipConstants.XXWIP10062);
    }
    pageParams.put(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID, batchId);
    pageParams.put(XxwipConstants.URL_PARAM_SEARCH_MTL_DTL_ID, mtlDtlId);

    return pageParams;

  } // doDetail

  /***************************************************************************
   * 検索処理を行うメソッドです。
   * @param searchBatchId - 検索用バッチID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearch(
    String searchBatchId
    ) throws OAException
  {
    // 必須チェックを行います。
    if (XxcmnUtility.isBlankOrNull(searchBatchId))
    {
      // OA例外リストを生成します。
      ArrayList exceptions = new ArrayList(2);
      //トークンを生成します。
      MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_ITEM, "検索条件：手配No") };
      exceptions.add(new OAException(XxcmnConstants.APPL_XXWIP, 
                                     XxwipConstants.XXWIP10008, 
                                     tokens));
      // いずれかのチェックがNGであった場合、スタックしたOA例外をスローします。
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
    // 検索を実行します。
    xbhvo.initQuery(searchBatchId);
    OARow row = (OARow)xbhvo.first();
    String trustProcessUnitPriceReject   = XxcmnConstants.STRING_FALSE;
    String othersCostReject              = XxcmnConstants.STRING_FALSE;
    String trustProcessUnitPriceRequired = XxcmnConstants.STRING_NO;
    if (row != null)
    {
      // 投入口ポップリストを取得します。
      SlitVOImpl svo = getSlitVO1();
      svo.initQuery(row.getAttribute("RoutingId").toString());

      // 出来高実績数が未入力の場合、指図総数をコピーします。
      String actualQty    = (String)row.getAttribute("ActualQty");
      String directionQty = (String)row.getAttribute("DirectionQty");
      if (XxcmnUtility.isBlankOrNull(actualQty) 
       || XxcmnUtility.chkCompareNumeric(3, actualQty, XxcmnConstants.STRING_ZERO))
      {
        row.setAttribute("ActualQty", directionQty);        
      }
      // 内外区分を取得し、自社の場合、委託加工単価、その他金額を無効にします。
      String inOutType = (String)row.getAttribute("InOutType");
      if (XxcmnUtility.isEquals(inOutType, XxwipConstants.IN_OUT_TYPE_JISHA)) 
      {
        trustProcessUnitPriceReject   = XxcmnConstants.STRING_TRUE;
        othersCostReject              = XxcmnConstants.STRING_TRUE;
      } else 
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
        // 委託加工単価の必須設定        
        trustProcessUnitPriceRequired = XxcmnConstants.STRING_UI_ONLY;
      }
    }
    // 副産物情報VO取得
    XxwipBatchCoProdVOImpl xbcvo = getXxwipBatchCoProdVO1();
    // 検索を実行します。
    xbcvo.initQuery(searchBatchId);
    // 投入情報VO取得
    XxwipBatchInvestVOImpl xbivo = getXxwipBatchInvestVO1();
    // 検索を実行します。
    xbivo.initQuery(searchBatchId);
    OARow row1 = (OARow)xbivo.first();
    if (row1 != null)
    {
      row1.setAttribute("SelectFlag", XxcmnConstants.STRING_Y);
    }
    // 打込情報VO取得
    XxwipBatchReInvestVOImpl xbrivo = getXxwipBatchReInvestVO1();
    // 検索を実行します。
    xbrivo.initQuery(searchBatchId);
    OARow row2 = (OARow)xbrivo.first();
    if (row2 != null)
    {
      row2.setAttribute("SelectFlag", XxcmnConstants.STRING_Y);
    }
    // 合計情報VO取得
    XxwipBatchTotalVOImpl xbtvo = getXxwipBatchTotalVO1();
    // 検索を実行します。
    xbtvo.initQuery(searchBatchId);
    // レンダリング制御
    handleVolumeActualEvent(
      XxcmnConstants.STRING_FALSE, 
      XxcmnConstants.STRING_TRUE, 
      XxcmnConstants.STRING_TRUE, 
      XxcmnConstants.STRING_TRUE,
      trustProcessUnitPriceReject,
      othersCostReject,
      trustProcessUnitPriceRequired);

  } // doSearch

  /***************************************************************************
   * 生産日のコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyProductDate()
  {
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl vo = getXxwipBatchHeaderVO1();
    OARow row           = (OARow)vo.first();
    Date productDate    = (Date)row.getAttribute("ProductDate");
    Date makerDate      = (Date)row.getAttribute("MakerDate");
    Date expirationDate = null;
    row.setAttribute("MakerDate", productDate);
    // 製造日コピー処理を呼び出します。
    copyMakerDate();

  } // copyProductDate

  /***************************************************************************
   * 製造日のコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyMakerDate()
  {
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl vo = getXxwipBatchHeaderVO1();
    OARow row           = (OARow)vo.first();
    Date makerDate      = (Date)row.getAttribute("MakerDate");
    Date expirationDate = (Date)row.getAttribute("ExpirationDate");
    Number itemId       = (Number)row.getAttribute("ItemId");
    // 賞味期限を算出
    expirationDate = XxwipUtility.getExpirationDate(getOADBTransaction(),
                                                    itemId,
                                                    makerDate);
    row.setAttribute("ExpirationDate", expirationDate);

  } // copyMakerDate

  /***************************************************************************
   * 画面制御を行うメソッドです。
   * @param goBtnReject          - 「適用」ボタン無効
   * @param addRowInvestRender   - 投入情報タブ「行挿入」レンダリング
   * @param addRowReInvestRender - 打込情報タブ「行挿入」レンダリング
   * @param addRowCoProdRender   - 副産物情報タブ「行挿入」レンダリング
   * @param trustProcessUnitPriceReject   - バッチヘッダ情報「加工単価」無効
   * @param othersCostReject   - バッチヘッダ情報「その他金額」無効
   * @param trustProcessUnitPriceRequired - バッチヘッダ情報「加工単価」必須
   ***************************************************************************
   */
  public void handleVolumeActualEvent(
    String goBtnReject,
    String addRowInvestRender,
    String addRowReInvestRender,
    String addRowCoProdRender,
    String trustProcessUnitPriceReject,
    String othersCostReject,
    String trustProcessUnitPriceRequired
  )
  {
    XxwipVolumeActualPVOImpl vo = getXxwipVolumeActualPVO1();
    OARow row       = (OARow)vo.first();
    if (row != null) 
    {
      // 適用ボタン制御
      if (XxcmnConstants.STRING_TRUE.equals(goBtnReject)) 
      {
        row.setAttribute("GoBtnReject", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(goBtnReject)) 
      {
        row.setAttribute("GoBtnReject", Boolean.FALSE);  
      }
      // 投入情報タブの行挿入制御
      if (XxcmnConstants.STRING_TRUE.equals(addRowInvestRender)) 
      {
        row.setAttribute("AddRowInvestRender", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(addRowInvestRender))  
      {
        row.setAttribute("AddRowInvestRender", Boolean.FALSE);  
      }
      // 打込情報タブの行挿入制御
      if (XxcmnConstants.STRING_TRUE.equals(addRowReInvestRender)) 
      {
        row.setAttribute("AddRowReInvestRender", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(addRowReInvestRender))  
      {
        row.setAttribute("AddRowReInvestRender", Boolean.FALSE);  
      }
      // 副産物情報タブの行挿入制御
      if (XxcmnConstants.STRING_TRUE.equals(addRowCoProdRender)) 
      {
        row.setAttribute("AddRowCoProdRender", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(addRowCoProdRender)) 
      {
        row.setAttribute("AddRowCoProdRender", Boolean.FALSE);  
      }
      // 委託加工単価の表示制御
      if (XxcmnConstants.STRING_TRUE.equals(trustProcessUnitPriceReject)) 
      {
        row.setAttribute("TrustProcessUnitPriceReject", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(trustProcessUnitPriceReject)) 
      {
        row.setAttribute("TrustProcessUnitPriceReject", Boolean.FALSE);  
      }
      // その他金額の表示制御
      if (XxcmnConstants.STRING_TRUE.equals(othersCostReject)) 
      {
        row.setAttribute("OthersCostReject", Boolean.TRUE);  
      } else if (XxcmnConstants.STRING_FALSE.equals(othersCostReject)) 
      {
        row.setAttribute("OthersCostReject", Boolean.FALSE);  
      }
      if (XxcmnUtility.isBlankOrNull(trustProcessUnitPriceRequired)) 
      {
        row.setAttribute("TrustProcessUnitPriceRequired", XxcmnConstants.STRING_NO);  
      } else 
      {
        row.setAttribute("TrustProcessUnitPriceRequired", trustProcessUnitPriceRequired);  
      }
      
    }
  } // handleVolumeActualEvent

  /***************************************************************************
   * 行挿入処理を行うメソッドです。
   * 
   * @param tabType - タブタイプ　0：投入、1：打込、2：副産物
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void addRow(
    String tabType
  ) throws OAException
  {
    OAViewObject vo = null;
    OARow row       = null;

    // 投入情報タブ
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      OAViewObject hdrVo = getXxwipBatchHeaderVO1();
      OARow hdrRow       = (OARow)hdrVo.first();
      // 投入情報VO取得
      vo  = getXxwipBatchInvestVO1();
      row = (OARow)vo.createRow();
      // Switcherの制御
      row.setAttribute("ItemNoSwitcher",      "ItemNoInvestEnable");
      row.setAttribute("DeleteSwitcher",      "DeleteInvestEnable");
      row.setAttribute("LineType",            new Number(XxwipConstants.LINE_TYPE_INVEST_NUM));
      row.setAttribute("InventoryLocationId", hdrRow.getAttribute("InventoryLocationId"));
      row.setAttribute("DestinationType",     hdrRow.getAttribute("DestinationType"));
      // 新缶煎区分が「Y」の場合
      if (XxcmnConstants.STRING_Y.equals(hdrRow.getAttribute("Sinkansentype"))) 
      {
        row.setAttribute("SlitSwitcher", "SlitInvestEnable");
      } else 
      {
        row.setAttribute("SlitSwitcher", "SlitInvestDisable");
      }
      vo.last();
      vo.next();
      vo.insertRow(row);
      row.setNewRowState(Row.STATUS_INITIALIZED);
      // レンダリング制御
      handleVolumeActualEvent(
        null, 
        XxcmnConstants.STRING_FALSE, 
        null, 
        null,
        null,
        null,
        null);
    // 打込情報タブ
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      OAViewObject hdrVo = getXxwipBatchHeaderVO1();
      OARow hdrRow       = (OARow)hdrVo.first();
      // 打込情報VO取得
      vo  = getXxwipBatchReInvestVO1();
      row = (OARow)vo.createRow();
      // Switcherの制御
      row.setAttribute("ItemNoSwitcher",      "ItemNoReInvestEnable");
      row.setAttribute("DeleteSwitcher",      "DeleteReInvestEnable");
      row.setAttribute("LineType",            new Number(XxwipConstants.LINE_TYPE_INVEST_NUM));
      row.setAttribute("InventoryLocationId", hdrRow.getAttribute("InventoryLocationId"));
      row.setAttribute("DestinationType",     hdrRow.getAttribute("DestinationType"));      
      vo.last();
      vo.next();
      vo.insertRow(row);
      row.setNewRowState(Row.STATUS_INITIALIZED);
      // レンダリング制御
      handleVolumeActualEvent(
        null, 
        null, 
        XxcmnConstants.STRING_FALSE, 
        null,
        null,
        null,
        null);
    // 副産物情報タブ
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      // 副産物情報VO取得
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.createRow();
      row.setAttribute("ItemNoSwitcher", "ItemNoCoProdEnable");
      row.setAttribute("LineType",       new Number(XxwipConstants.LINE_TYPE_CO_PROD_NUM));
      vo.last();
      vo.next();
      vo.insertRow(row);
      row.setNewRowState(Row.STATUS_INITIALIZED);
      // レンダリング制御
      handleVolumeActualEvent(
        null, 
        null, 
        null, 
        XxcmnConstants.STRING_FALSE,
        null,
        null,
        null);
    }
  } // addRow

  /***************************************************************************
   * 適用処理を行うメソッドです。
   * @param batchId - バッチID
   * @param tabType - タブタイプ　0：投入、1:打込、2：副産物
   ***************************************************************************
   */
  public String apply(
    String batchId,
    String tabType
    )
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag  = false;
    boolean warnFlag = false;
    String  exeType  = XxcmnConstants.STRING_ZERO;

    // バッチヘッダ情報チェック処理
    checkItem(tabType, exceptions);
    // チェックがNGであった場合、スタックしたOA例外をスローします。
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    } else
    {
      getOADBTransaction().executeCommand("SAVEPOINT " + XxwipConstants.SAVE_POINT_XXWIP200001J);
      // ロック取得処理
      getRowLock(batchId);
      // 排他制御
      chkEexclusiveControl();
      // ロット登録・更新処理
      if (lotExecute()) 
      {
        exeFlag = true;  
      }
      // ステータス更新処理
      if (updateStatus()) 
      {
        exeFlag = true;  
      }
      // 完成品の割当処理
      if (lineAllocation(XxwipConstants.LINE_TYPE_PROD)) 
      {
        exeFlag = true;  
      }
      // 投入品・副産物の原料登録処理
      if (insertMaterialLine(tabType)) 
      {
        exeFlag = true;  
      }
      // 副産物の更新処理
      if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
      {
        // 副産物・完成品の原料更新処理
        if (updateMaterialLine(true)) 
        {
          exeFlag = true;  
        }
      } else
      {
        // 完成品の原料更新処理
        if (updateMaterialLine(false)) 
        {
          exeFlag = true;  
        }
      }
      // 副産物の割当処理
      if (lineAllocation(XxwipConstants.LINE_TYPE_CO_PROD)) 
      {
        exeFlag = true;  
      }
      // 処理が行われた場合
      if (exeFlag) 
      {
        // バッチセーブ
        XxwipUtility.saveBatch(getOADBTransaction(), batchId);
        // 在庫単価更新関数
        XxwipUtility.updateInvPrice(getOADBTransaction(), batchId);

        // バッチヘッダ情報VO取得
        XxwipBatchHeaderVOImpl xbhvo = getXxwipBatchHeaderVO1();
        OARow  hdrRow        = (OARow)xbhvo.first();
        String inOutType     = (String)hdrRow.getAttribute("InOutType");
        String trustCalcType = (String)hdrRow.getAttribute("TrustCalculateType");
        // 委託先の場合
        if (XxwipConstants.IN_OUT_TYPE_ITAKU.equals(inOutType)) 
        {
          // 委託加工費更新関数
          XxwipUtility.updateTrustPrice(getOADBTransaction(), batchId);
        }
        // 品質検査
        if (XxcmnConstants.RETURN_WARN.equals(doQtInspection())) 
        {
          warnFlag = true;
        }
      }
    }
    // 警告終了
    if (warnFlag) 
    {
      exeType = XxcmnConstants.RETURN_WARN;
    // 処理正常終了
    } else if (exeFlag)
    {
      exeType = XxcmnConstants.RETURN_SUCCESS;
    } else 
    {
      exeType = XxcmnConstants.RETURN_NOT_EXE;
    }
    return exeType;
  } // apply

  /***************************************************************************
   * コミット処理を行うメソッドです。
   * @param batchId - バッチID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doCommit(
    String batchId
  ) throws OAException
  {
    // コミット
    getOADBTransaction().commit();
    // 初期化処理
    initialize();
    // 再検索
    doSearch(batchId);
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

  /***************************************************************************
   * チェック処理を行うメソッドです。
   * 
   * @param tabType - タブタイプ　0：投入、1:打込、2：副産物
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void checkItem(
    String tabType,
    ArrayList exceptions
  ) throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    // バッチヘッダ情報VO取得
    vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    // システム日付を取得
    Date currentDate = getOADBTransaction().getCurrentDBDate();
    // 生産日
    Object productDate = row.getAttribute("ProductDate");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(productDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ProductDate",
                            productDate,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    } else 
    {
      if (!XxcmnUtility.chkCompareDate(2, currentDate, (Date)productDate)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ProductDate",
                              productDate,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10007));
      }
    }
    // 製造日
    Object makerDate = row.getAttribute("MakerDate");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(makerDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "MakerDate",
                            makerDate,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    }
    // 賞味期限日
    Object expirationDate = row.getAttribute("ExpirationDate");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(expirationDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ExpirationDate",
                            expirationDate,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    }
    // 出来高総数
    Object actualQty = row.getAttribute("ActualQty");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(actualQty)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ActualQty",
                            actualQty,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    } else
    {
      // 数値チェック
      if (!XxcmnUtility.chkNumeric(actualQty, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ActualQty",
                              actualQty,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10061));
      // 数量チェック
      } else if (XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, actualQty))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ActualQty",
                              actualQty,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10063));
      }
    }
    // 在庫入数
    Object entityInner = row.getAttribute("EntityInner");
    // 必須チェック
    if (XxcmnUtility.isBlankOrNull(entityInner))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "EntityInner",
                            entityInner,
                            XxcmnConstants.APPL_XXWIP,         
                            XxwipConstants.XXWIP10058));
    } else
    {
      if (!XxcmnUtility.chkNumeric(entityInner, 3, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "EntityInner",
                              entityInner,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10061));
      }
    }
    // 内外区分
    String inOutType = (String)row.getAttribute("InOutType");    
    // 内外区分が委託先の場合
    if (XxwipConstants.IN_OUT_TYPE_ITAKU.equals(inOutType))
    {
      // 委託加工単価がブランクの場合、自動導出を行う。
      if (XxcmnUtility.isBlankOrNull(row.getAttribute("TrustProcessUnitPrice"))) 
      {
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
        // 戻り値が0で無い場合、値をセット
        if (XxcmnUtility.chkCompareNumeric(1, 
                                           retMap.get("totalAmount"), 
                                           XxcmnConstants.STRING_ZERO)) 
        {
          row.setAttribute("TrustProcessUnitPrice", retMap.get("totalAmount"));
        }
        row.setAttribute("TrustCalculateType",    retMap.get("calcType"));
      }
      
      // 委託加工単価
      Object trustProcUnitPrice = row.getAttribute("TrustProcessUnitPrice");
      if (XxcmnUtility.isBlankOrNull(trustProcUnitPrice)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "TrustProcessUnitPrice",
                              trustProcUnitPrice,
                              XxcmnConstants.APPL_XXWIP,         
                              XxwipConstants.XXWIP10058));
      } else
      {
        if (!XxcmnUtility.chkNumeric(trustProcUnitPrice, 9, 2)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "TrustProcessUnitPrice",
                                trustProcUnitPrice,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10061));
        }
      }
      // その他金額
      Object othersCost = row.getAttribute("OthersCost");
      if (!XxcmnUtility.isBlankOrNull(othersCost)) 
      {
        // 数値チェック
        if (!XxcmnUtility.chkNumeric(othersCost, 13, 0)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "OthersCost",
                                othersCost,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10061));
        }
      }
    }
    // 投入情報タブ
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      // 投入情報VO取得
      vo  = getXxwipBatchInvestVO1();    
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoInvestEnable");
      // 1行も無い場合はエラーチェックは行わない。
      if (row != null) 
      {
        // 品目コード
        Object itemNo = row.getAttribute("ItemNo");
        // 必須チェック
        if (XxcmnUtility.isBlankOrNull(itemNo))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ItemNo",
                                itemNo,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        }
      }
    // 打込情報タブ
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      // 打込情報VO取得
      vo  = getXxwipBatchReInvestVO1();
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoReInvestEnable");
      // 1行も無い場合はエラーチェックは行わない。
      if (row != null) 
      {
        // 品目コード
        Object itemNo = row.getAttribute("ItemNo");
        // 必須チェック
        if (XxcmnUtility.isBlankOrNull(itemNo))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ItemNo",
                                itemNo,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        }
      }
    // 副産物情報タブ
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      // 副産物情報VO取得
      vo  = getXxwipBatchCoProdVO1();
      // 更新行取得
      Row[] rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoCoProdDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int i = 0; i < rows.length; i++)
        {
          row = (OARow)rows[i];
          // 在庫入数
          entityInner = row.getAttribute("EntityInner");
          // 必須チェック
          if (XxcmnUtility.isBlankOrNull(entityInner))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "EntityInner",
                                  entityInner,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10058));
          } else
          {
            if (!XxcmnUtility.chkNumeric(entityInner, 3, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "EntityInner",
                                    entityInner,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            }
          }
          // 出来高総数
          actualQty = row.getAttribute("ActualQty");
          // 必須チェック
          if (XxcmnUtility.isBlankOrNull(actualQty)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "ActualQty",
                                  actualQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10058));
          } else
          {
            // 数値チェック
            if (!XxcmnUtility.chkNumeric(actualQty, 9, 3)) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ActualQty",
                                    actualQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10061));
            // 数量チェック
            } else if (XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, actualQty))
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ActualQty",
                                    actualQty,
                                    XxcmnConstants.APPL_XXWIP,         
                                    XxwipConstants.XXWIP10063));
            }
          }
        }
      }
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoCoProdEnable");
      // 1行も無い場合はエラーチェックは行わない。
      if (row != null) 
      {
        // 品目コード
        Object itemNo = row.getAttribute("ItemNo");
        // 必須チェック
        if (XxcmnUtility.isBlankOrNull(itemNo))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ItemNo",
                                itemNo,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        } else
        {
          // 重複チェック
          // 他の行が無い場合はチェックしない
          if ((rows != null) && (rows.length > 0))
          {
            for (int i = 0; i < rows.length; i++)
            {
              Row chkRow = (OARow)rows[i];
              if (XxcmnUtility.isEquals(itemNo, chkRow.getAttribute("ItemNo"))) 
              {
                MessageToken[] tokens = { 
                  new MessageToken(XxwipConstants.TOKEN_ITEM, XxwipConstants.TOKEN_NAME_ITEM) };
                exceptions.add( new OAAttrValException(
                                      OAAttrValException.TYP_VIEW_OBJECT,          
                                      vo.getName(),
                                      row.getKey(),
                                      "ItemNo",
                                      itemNo,
                                      XxcmnConstants.APPL_XXWIP,         
                                      XxwipConstants.XXWIP10023,
                                      tokens));
              }
            }
          }
        }
        // 在庫入数
        entityInner = row.getAttribute("EntityInner");
        // 必須チェック
        if (XxcmnUtility.isBlankOrNull(entityInner))
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "EntityInner",
                                entityInner,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        } else
        {
          if (!XxcmnUtility.chkNumeric(entityInner, 3, 3)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "EntityInner",
                                  entityInner,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10061));
          }
        }
        // 出来高総数
        actualQty = row.getAttribute("ActualQty");
        // 必須チェック
        if (XxcmnUtility.isBlankOrNull(actualQty)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ActualQty",
                                actualQty,
                                XxcmnConstants.APPL_XXWIP,         
                                XxwipConstants.XXWIP10058));
        } else
        {
          // 数値チェック
          if (!XxcmnUtility.chkNumeric(actualQty, 9, 3)) 
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "ActualQty",
                                  actualQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10061));
          // 数量チェック
          } else if (XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, actualQty))
          {
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  row.getKey(),
                                  "ActualQty",
                                  actualQty,
                                  XxcmnConstants.APPL_XXWIP,         
                                  XxwipConstants.XXWIP10063));
          }
        }
      }    
    }    
  } // checkItem

  /*****************************************************************************
   * ステータスの更新を行います。
   ****************************************************************************/
  public boolean updateStatus()
  {
    OARow row       = null;
    boolean exeFlag = false;

    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    // 業務ステータス
    String dutyStatusCode = (String)row.getAttribute("DutyStatusCode");
    if (!XxwipConstants.DUTY_STATUS_COM.equals(dutyStatusCode)) 
    {
      // バッチID
      Number batchId  = (Number)row.getAttribute("BatchId");
      exeFlag = XxwipUtility.updateStatus(
                  getOADBTransaction(),
                  batchId);
    }
    return exeFlag;

  } // updateStatus

  /*****************************************************************************
   * ロットの追加・更新を行います。
   * @return 処理フラグ true：処理実行、false：処理未実行
   ****************************************************************************/
  public boolean lotExecute()
  {
    boolean exeFlag = false;

    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String lotNo         = (String)hdrRow.getAttribute("LotNo");         // ロットNo
    Date makerDate       = (Date)hdrRow.getAttribute("MakerDate");       // 製造日
    Date baseMakerDate   = (Date)hdrRow.getAttribute("BaseMakerDate");   // 製造日(DB)
    Number batchId       = (Number)hdrRow.getAttribute("BatchId");       // バッチID
    Number itemId        = (Number)hdrRow.getAttribute("ItemId");        // 品目ID
    Number lotId         = (Number)hdrRow.getAttribute("LotId");         // ロットID
    String uniqueSign    = (String)hdrRow.getAttribute("UniqueSign");    // 固有記号
    Date expirationDate  = (Date)hdrRow.getAttribute("ExpirationDate");  // 賞味期限日
    String routingNo     = (String)hdrRow.getAttribute("RoutingNo");     // ラインNo
    String slipType      = (String)hdrRow.getAttribute("SlipType");      // 伝票区分
    String itemClassCode = (String)hdrRow.getAttribute("ItemClassCode"); // 品目区分

    // 完成品の場合
    if (!XxcmnUtility.isEquals(makerDate, baseMakerDate)
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Type"),           hdrRow.getAttribute("BaseType"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank1"),          hdrRow.getAttribute("BaseRank1"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank2"),          hdrRow.getAttribute("BaseRank2"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MaterialDesc"),   hdrRow.getAttribute("BaseMaterialDesc"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("EntityInner"),    hdrRow.getAttribute("BaseEntityInner"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ProductDate"),    hdrRow.getAttribute("BaseProductDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MakerDate"),      hdrRow.getAttribute("BaseMakerDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ExpirationDate"), hdrRow.getAttribute("BaseExpirationDate")))
    {
      String entityInner  = (String)hdrRow.getAttribute("EntityInner");    // 在庫入数
      String materialDesc = (String)hdrRow.getAttribute("MaterialDesc");   // 摘要
      String qtType       = (String)hdrRow.getAttribute("QtType");         // 試験有無区分
      String itemNo       = (String)hdrRow.getAttribute("ItemNo");         // 品目コード
      String type         = (String)hdrRow.getAttribute("Type");           // タイプ
      String rank1        = (String)hdrRow.getAttribute("Rank1");          // ランク１
      String rank2        = (String)hdrRow.getAttribute("Rank2");          // ランク２
      // 引数を設定します。
      HashMap params = new HashMap();
      params.put("entityInner",    entityInner);
      params.put("materialDesc",   materialDesc);
      params.put("qtType",         qtType);
      params.put("type",           type);
      params.put("rank1",          rank1);
      params.put("rank2",          rank2);
      params.put("itemNo",         itemNo);
      params.put("itemId",         itemId);
      params.put("lotId",          lotId);
      params.put("makerDate",      makerDate);
      params.put("uniqueSign",     uniqueSign);
      params.put("expirationDate", expirationDate);
      params.put("lotNo",          lotNo);
      params.put("slipType",       slipType);
      params.put("routingNo",      routingNo);
      params.put("itemClassCode",  itemClassCode);
      exeFlag = XxwipUtility.lotExecute(
                  getOADBTransaction(),
                  lotNo,
                  hdrRow,
                  XxwipConstants.LINE_TYPE_PROD,
                  params);
    }
    // 完成品のロットNoを再取得
    lotNo = (String)hdrRow.getAttribute("LotNo");         // ロットNo
    // 副産物情報VO取得
    XxwipBatchCoProdVOImpl vo  = getXxwipBatchCoProdVO1();
    OARow row = (OARow)vo.first();
    int fetchedRowCount = vo.getFetchedRowCount();
    Row[] coProdRows = vo.getAllRowsInRange();
    if ((coProdRows != null) && (coProdRows.length > 0))
    {
      for (int i = 0; i < coProdRows.length; i++)
      {
        row = (OARow)coProdRows[i];
        // 副産物ロットNo
        String coProdLotNo = (String)row.getAttribute("LotNo");
        if (XxcmnUtility.isBlankOrNull(coProdLotNo)
        || !XxcmnUtility.isEquals(lotNo, coProdLotNo)
        || !XxcmnUtility.isEquals(row.getAttribute("Type"),        
                                  row.getAttribute("BaseType"))
        || !XxcmnUtility.isEquals(row.getAttribute("Rank1"),               
                                  row.getAttribute("BaseRank1"))
        || !XxcmnUtility.isEquals(row.getAttribute("Rank2"),               
                                  row.getAttribute("BaseRank2"))
        || !XxcmnUtility.isEquals(row.getAttribute("EntityInner"),         
                                  row.getAttribute("BaseEntityInner")))
        {
          itemId              = (Number)row.getAttribute("ItemId");       // 品目ID
          lotId               = (Number)row.getAttribute("LotId");        // ロットID
          String entityInner  = (String)row.getAttribute("EntityInner");  // 在庫入数
          String type         = (String)row.getAttribute("Type");         // タイプ
          String rank1        = (String)row.getAttribute("Rank1");        // ランク１
          String rank2        = (String)row.getAttribute("Rank2");        // ランク２
          String qtType       = (String)row.getAttribute("QtType");       // 試験有無区分
          String itemNo       = (String)row.getAttribute("ItemNo");       // 品目コード
          // 引数を設定します。
          HashMap params = new HashMap();
          params.put("entityInner",    entityInner);
          params.put("materialDesc",   null);
          params.put("qtType",         qtType);
          params.put("type",           type);
          params.put("rank1",          rank1);
          params.put("rank2",          rank2);
          params.put("itemNo",         itemNo);
          params.put("itemId",         itemId);
          params.put("lotId",          lotId);
          params.put("makerDate",      makerDate);
          params.put("uniqueSign",     uniqueSign);
          params.put("expirationDate", expirationDate);
          params.put("lotNo",          coProdLotNo);
          params.put("slipType",       slipType);
          params.put("routingNo",      routingNo);
          exeFlag = XxwipUtility.lotExecute(
                      getOADBTransaction(),
                      lotNo,
                      row,
                      XxwipConstants.LINE_TYPE_CO_PROD,
                      params);
        }
      }
    }
    return exeFlag;
  } // lotExecute

  /*****************************************************************************
   * 原料の更新を行います。
   * @param isCoProd - 副産物更新可否
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public boolean updateMaterialLine(
    boolean isCoProd
  ) throws OAException 
  {
    boolean exeFlag = false;

    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl hdrVo = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    if (hdrRow == null) 
    {
      return false;
    }
    // 完成品に変更があった場合
    /* ----------------------------------
      タイプ
      ランク１
      ランク２
      摘要
      生産日
      製造日
      賞味期限日
      在庫入数
      委託計算区分
      委託加工単価
      その他金額
     ---------------------------------- */
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("Type"),               
                               hdrRow.getAttribute("BaseType"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank1"),              
                               hdrRow.getAttribute("BaseRank1"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("Rank2"),              
                               hdrRow.getAttribute("BaseRank2"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MaterialDesc"),       
                               hdrRow.getAttribute("BaseMaterialDesc"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ProductDate"),        
                               hdrRow.getAttribute("BaseProductDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("MakerDate"),          
                               hdrRow.getAttribute("BaseMakerDate"))  
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ExpirationDate"),     
                               hdrRow.getAttribute("BaseExpirationDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("EntityInner"),        
                               hdrRow.getAttribute("BaseEntityInner"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("TrustCalculateType"),    
                               hdrRow.getAttribute("BaseTrustCalculateType"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("TrustProcessUnitPrice"),    
                               hdrRow.getAttribute("BaseTrustProcessUnitPrice"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("OthersCost"),         
                               hdrRow.getAttribute("BaseOthersCost")))
    {
      Number mtlDtlId      = (Number)hdrRow.getAttribute("MaterialDetailId");
      String entityInner   = (String)hdrRow.getAttribute("EntityInner");
      Number lineType      = (Number)hdrRow.getAttribute("LineType");
      Date expirationDate  = (Date)hdrRow.getAttribute("ExpirationDate");
      Date productDate     = (Date)hdrRow.getAttribute("ProductDate");
      Date makerDate       = (Date)hdrRow.getAttribute("MakerDate");
      String type          = (String)hdrRow.getAttribute("Type");
      String rank1         = (String)hdrRow.getAttribute("Rank1");
      String rank2         = (String)hdrRow.getAttribute("Rank2");
      String mtlDesc       = (String)hdrRow.getAttribute("MaterialDesc");
      String trustCalcType = (String)hdrRow.getAttribute("TrustCalculateType");
      String othersCost    = (String)hdrRow.getAttribute("OthersCost");
      String trustProcUnitPrice = (String)hdrRow.getAttribute("TrustProcessUnitPrice");
      // 引数を設定します。
      HashMap params = new HashMap();
      params.put("mtlDtlId",       mtlDtlId);
      params.put("lineType",       lineType);
      params.put("type",           type);
      params.put("rank1",          rank1);
      params.put("rank2",          rank2);
      params.put("mtlDesc",        mtlDesc);
      params.put("entityInner",    entityInner);
      params.put("productDate",    productDate);
      params.put("makerDate",      makerDate);
      params.put("expirationDate", expirationDate);
      params.put("trustCalcType",  trustCalcType);
      params.put("othersCost",     othersCost);
      params.put("trustProcUnitPrice", trustProcUnitPrice);
      exeFlag = XxwipUtility.updateMaterialLine(
                  getOADBTransaction(),
                  params);
    }
    // 副産物情報タブ
    if (isCoProd) 
    {
      // 副産物情報VO取得
      XxwipBatchCoProdVOImpl vo = getXxwipBatchCoProdVO1();
      OARow row       = null;
      // 更新行取得
      Row[] rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoCoProdDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int i = 0; i < rows.length; i++)
        {
          row = (OARow)rows[i];
          // 変更があった場合
          if (!XxcmnUtility.isEquals(row.getAttribute("Type"),            
                                     row.getAttribute("BaseType"))
           || !XxcmnUtility.isEquals(row.getAttribute("Rank1"),                  
                                     row.getAttribute("BaseRank1"))
           || !XxcmnUtility.isEquals(row.getAttribute("Rank2"),                  
                                     row.getAttribute("BaseRank2"))
           || !XxcmnUtility.isEquals(row.getAttribute("EntityInner"),            
                                     row.getAttribute("BaseEntityInner")))
          {
            String entityInner = (String)row.getAttribute("EntityInner");
            String type        = (String)row.getAttribute("Type");
            String rank1       = (String)row.getAttribute("Rank1");
            String rank2       = (String)row.getAttribute("Rank2");
            Number mtlDtlId    = (Number)row.getAttribute("MaterialDetailId");
            Number lineType    = (Number)row.getAttribute("LineType");
            // 引数を設定します。
            HashMap params = new HashMap();
            params.put("type",        type);
            params.put("rank1",       rank1);
            params.put("rank2",       rank2);
            params.put("lineType",    lineType);
            params.put("entityInner", entityInner);
            params.put("mtlDtlId",    mtlDtlId);
            exeFlag = XxwipUtility.updateMaterialLine(
                        getOADBTransaction(),
                        params);
          }
        }
      }
    }
    // 日付が変更された場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ProductDate"),        
                               hdrRow.getAttribute("BaseProductDate"))) 
    {
      // バッチID
      Number batchId = (Number)hdrRow.getAttribute("BatchId");
      // 処理日付更新関数を実行します。
      changeTransDateAll(batchId);
    }
    return exeFlag;
  } // updateMaterialLine

  /*****************************************************************************
   * 原料の追加を行います。
   * @param tabType - タブタイプ　0：投入、1：打込、2：副産物
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public boolean insertMaterialLine(
    String tabType
  ) throws OAException 
  {
    OAViewObject vo  = null;
    OARow row        = null;
    boolean exeFlag  = false;
    String  utkType  = null;
    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // バッチID
    Number batchId      = (Number)hdrRow.getAttribute("BatchId");
    Date expirationDate = null;
    Date productDate    = null;
    Date makerDate      = null;
    // 投入情報
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      vo  = getXxwipBatchInvestVO1();
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoInvestEnable");
    // 打込情報
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      vo  = getXxwipBatchReInvestVO1();
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoReInvestEnable");
      utkType = XxcmnConstants.STRING_Y;
    // 副産物の場合
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoCoProdEnable");
      expirationDate = (Date)hdrRow.getAttribute("ExpirationDate");
      productDate    = (Date)hdrRow.getAttribute("ProductDate");
      makerDate      = (Date)hdrRow.getAttribute("MakerDate");
      row.setAttribute("BatchId", batchId);
    }
    if (row != null) 
    {
      Number itemId   = (Number)row.getAttribute("ItemId");
      Number lineType = (Number)row.getAttribute("LineType");
      String itemUm   = (String)row.getAttribute("ItemUm");
      String slit     = null;
      String type     = null;
      String rank1    = null;
      String rank2    = null;
      String entityInner = null;
      if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
      {
        // 投入口
        slit = (String)row.getAttribute("Slit");
      } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
      {
        entityInner = (String)row.getAttribute("EntityInner");
        type  = (String)row.getAttribute("Type");
        rank1 = (String)row.getAttribute("Rank1");
        rank2 = (String)row.getAttribute("Rank2");
      }
      // 引数を設定します。
      HashMap params = new HashMap();
      params.put("batchId",  batchId);
      params.put("itemId",   itemId);
      params.put("itemUm",   itemUm);
      params.put("type",     type);
      params.put("rank1",    rank1);
      params.put("rank2",    rank2);
      params.put("slit",     slit);
      params.put("utkType",  utkType);
      params.put("lineType", lineType);
      params.put("entityInner",    entityInner);
      params.put("productDate",    productDate);
      params.put("makerDate",      makerDate);
      params.put("expirationDate", expirationDate);
      exeFlag = XxwipUtility.insertMaterialLine(
                  getOADBTransaction(),
                  row,
                  params,
                  tabType);
    }
    return exeFlag;
  } // insertMaterialLine

  /*****************************************************************************
   * 指定された行を削除します。
   * @param tabType - タブタイプ　0：投入、1：打込、2：副産物
   * @param batchId - 生産バッチID
   * @param mtlDtlId - 生産原料詳細ID
   ****************************************************************************/
  public void deleteMaterialLine(
    String tabType,
    String batchId,
    String mtlDtlId
  ) throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    boolean exeFlag = false;

    // 投入情報
    if (XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
    {
      vo = getXxwipBatchInvestVO1();
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoInvestEnable");
    // 打込情報
    } else if (XxwipConstants.TAB_TYPE_REINVEST.equals(tabType)) 
    {
      vo = getXxwipBatchReInvestVO1();
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoReInvestEnable");
    // 副産物の場合
    } else if (XxwipConstants.TAB_TYPE_CO_PROD.equals(tabType)) 
    {
      vo = getXxwipBatchCoProdVO1();
      // 挿入行取得
      row = (OARow)vo.getFirstFilteredRow("ItemNoSwitcher", "ItemNoCoProdEnable");
    }
    // 挿入行が存在する場合
    if (row != null) 
    {
      // 挿入行削除
      row.remove();
      // レンダリング制御
      handleVolumeActualEvent(
        null, 
        XxcmnConstants.STRING_TRUE, 
        XxcmnConstants.STRING_TRUE, 
        XxcmnConstants.STRING_TRUE,
        null,
        null,
        null);
      // 削除完了メッセージを表示
      throw new OAException(
        XxcmnConstants.APPL_XXWIP,
        XxwipConstants.XXWIP30002, 
        null, 
        OAException.INFORMATION, 
        null);
    // 更新行削除
    } else
    {
      // 引数を設定します。
      HashMap params = new HashMap();
      params.put("batchId",  batchId);
      params.put("mtlDtlId", mtlDtlId);
      exeFlag = XxwipUtility.deleteMaterialLine(
                  getOADBTransaction(),
                  params);
    }
    // 処理フラグがTRUEの場合
    if (exeFlag) 
    {
      // バッチセーブ
      XxwipUtility.saveBatch(getOADBTransaction(), batchId);
      // 在庫単価更新関数
      XxwipUtility.updateInvPrice(getOADBTransaction(), batchId);
      // コミット
      getDBTransaction().commit();
      // 初期化処理
      initialize();
      // 再検索
      doSearch(batchId);
      // 削除完了メッセージを表示
      throw new OAException(
        XxcmnConstants.APPL_XXWIP,
        XxwipConstants.XXWIP30002, 
        null, 
        OAException.INFORMATION, 
        null);
    }
  } // deleteMaterialLine

  /*****************************************************************************
   * 割当の登録・更新を行います。
   * @param lineType - ラインタイプ　1：完成品、2：副産物
   * @return 処理フラグ true：処理実行、false：処理未実行
   * @throws OAException - OA例外
   ****************************************************************************/
  public boolean lineAllocation(
    String lineType
  ) throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    boolean exeFlag = false;

    // ヘッダ情報を取得します。
    vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    // 各種情報を取得します。
    Date   productDate = (Date)row.getAttribute("ProductDate");        // 生産日
    String location    = (String)row.getAttribute("DeliveryLocation"); // 保管場所
    String whseCode    = (String)row.getAttribute("WipWhseCode");      // 倉庫コード
    Number batchId     = (Number)row.getAttribute("BatchId");          // バッチID

    // 完成品の場合
    if (XxwipConstants.LINE_TYPE_PROD.equals(lineType))
    {
      String lotNo         = (String)row.getAttribute("LotNo");           // ロットNo
      Number lotId         = (Number)row.getAttribute("LotId");           // ロットID
      Number baseLotId     = (Number)row.getAttribute("BaseLotId");       // ロットID(DB)
      Number transId       = (Number)row.getAttribute("TransId");         // トランザクションID
      String actualQty     = (String)row.getAttribute("ActualQty");       // 実績数量
      String baseActualQty = (String)row.getAttribute("BaseActualQty");   // 実績数量(DB)
      Number mtlDtlId      = (Number)row.getAttribute("MaterialDetailId");// 生産原料詳細ID   
      Number itemId        = (Number)row.getAttribute("ItemId");          // 品目ID   
      Date baseProductDate = (Date)row.getAttribute("BaseProductDate");       // 生産日(DB)
      // 引数を設定します。
      HashMap params = new HashMap();
      params.put("batchId",     batchId);
      params.put("lotId",       lotId);
      params.put("mtlDtlId",    mtlDtlId);
      params.put("actualQty",   XxwipUtility.getRcvShipQty(getOADBTransaction(), "1", itemId, actualQty));
      params.put("location",    location);
      params.put("whseCode",    whseCode);
      params.put("productDate", productDate);
      // トランザクションIDがnullの場合
      if (XxcmnUtility.isBlankOrNull(transId)) 
      {
        // 割当追加APIを実行します。
        exeFlag = XxwipUtility.insertLineAllocation(
                    getOADBTransaction(),
                    params,
                    lineType);
      // トランザクションIDがnullでは無い場合
      } else 
      {
        // ロットID、生産日、実績数量が変更された場合
        if (!XxcmnUtility.isEquals(baseLotId,     lotId)
         || !XxcmnUtility.isEquals(productDate,   baseProductDate)
         || !XxcmnUtility.isEquals(baseActualQty, actualQty)) 
        {
          // 引数を設定します。
          params.put("transId",   transId);
          // 割当更新APIを実行します。
          exeFlag = XxwipUtility.updateLineAllocation(
                      getOADBTransaction(),
                      params,
                      lineType);
        }
      }
    // 副産物の場合
    } else 
    {
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.first();
      int fetchedRowCount = vo.getFetchedRowCount();
      Row[] coProdRows = vo.getAllRowsInRange();
      if ((coProdRows != null) && (coProdRows.length > 0))
      {
        for (int i = 0; i < coProdRows.length; i++)
        {
          row = (OARow)coProdRows[i];
          // 各種情報を取得します。
          String lotNo         = (String)row.getAttribute("LotNo");           // ロットNo
          Number lotId         = (Number)row.getAttribute("LotId");           // ロットID
          Number baseLotId     = (Number)row.getAttribute("BaseLotId");       // ロットID(DB)
          Number transId       = (Number)row.getAttribute("TransId");         // トランザクションID
          String actualQty     = (String)row.getAttribute("ActualQty");       // 実績数量
          String baseActualQty = (String)row.getAttribute("BaseActualQty");   // 実績数量(DB)
          Number mtlDtlId      = (Number)row.getAttribute("MaterialDetailId");// 生産原料詳細ID   
          // 引数を設定します。
          HashMap params = new HashMap();
          params.put("batchId",     batchId);
          params.put("lotId",       lotId);
          params.put("mtlDtlId",    mtlDtlId);
          params.put("actualQty",   actualQty);
          params.put("location",    location);
          params.put("whseCode",    whseCode);
          params.put("productDate", productDate);
          // トランザクションIDがnullの場合
          if (XxcmnUtility.isBlankOrNull(transId)) 
          {
            // 割当追加APIを実行します。
            exeFlag = XxwipUtility.insertLineAllocation(
                        getOADBTransaction(),
                        params,
                        lineType);
          // トランザクションIDがnullでは無い場合
          } else 
          {
            if (!XxcmnUtility.isEquals(baseLotId, lotId) 
             || !XxcmnUtility.isEquals(baseActualQty, actualQty)) 
            {
              // 引数を設定します。
              params.put("transId",   transId);
              // 割当更新APIを実行します。
              exeFlag = XxwipUtility.updateLineAllocation(
                          getOADBTransaction(),
                          params,
                          lineType);
            }
          }
        }
      }
    }
    return exeFlag;
  } // lineAllocation

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
    sb.append("    SELECT gbh.batch_id batch_id    "); // バッチID
    sb.append("    FROM   gme_batch_header     gbh "); // 生産バッチヘッダ
    sb.append("          ,gme_material_details gmd "); // 生産原料詳細
    sb.append("          ,ic_tran_pnd          itp "); // OPM保留在庫トランザクション
    sb.append("    WHERE  gbh.batch_id           = gmd.batch_id  ");
    sb.append("    AND    gmd.material_detail_id = itp.line_id   ");
    sb.append("    AND    gbh.batch_id           = TO_NUMBER(:1) ");
    sb.append("    FOR UPDATE OF gbh.batch_id, gmd.batch_id, itp.doc_id NOWAIT; ");
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
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
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
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getRowLock

  /***************************************************************************
   * 品質検査を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String doQtInspection() throws OAException 
  {
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;
    String exeType  = XxcmnConstants.RETURN_NOT_EXE;
    boolean warnFlag   = false; // 正常終了フラグ
    boolean exeFlag    = false; // 警告終了フラグ

    // ヘッダ情報を取得します。
    vo  = getXxwipBatchHeaderVO1();
    row = (OARow)vo.first();
    String qtType = (String)row.getAttribute("QtType");
    // 品質検査有無区分がYの場合
    if (XxwipConstants.QT_TYPE_ON.equals(qtType)) 
    {
      // 各種情報を取得
      Number lotId   = (Number)row.getAttribute("LotId");
      Number itemId  = (Number)row.getAttribute("ItemId");
      Number batchId = (Number)row.getAttribute("BatchId");
      // 品質検査Noを取得する。
      String qtNumber = getQtNumber(itemId, lotId);
      String retCode  = null;
      // 品質検査NoがNullの場合
      if (XxcmnUtility.isBlankOrNull(qtNumber)) 
      {
        // 新規
        retCode = XxwipUtility.doQtInspection(
                    getOADBTransaction(),
                    "1",
                    lotId,
                    itemId,
                    batchId,
                    null);
        if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
        {
          warnFlag = true;  
        } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
        {
          exeFlag  = true;
        }
      // 製造日、出来高数が変更された場合
      } else if (!XxcmnUtility.isEquals(row.getAttribute("MakerDate"), 
                                        row.getAttribute("BaseMakerDate"))
              || !XxcmnUtility.isEquals(row.getAttribute("ActualQty"),   
                                        row.getAttribute("BaseActualQty"))) 
      {
        // 更新
        retCode = XxwipUtility.doQtInspection(
                    getOADBTransaction(),
                    "2",
                    lotId,
                    itemId,
                    batchId,
                    qtNumber);
        if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
        {
          warnFlag = true;  
        } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
        {
          exeFlag  = true;
        }
      }
    }
    // 完成品の製造日を退避
    Date bhMakerDate     = (Date)row.getAttribute("MakerDate");
    Date bhBaseMakerDate = (Date)row.getAttribute("BaseMakerDate");
    // 副産物情報
    OAViewObject coProdVo = getXxwipBatchCoProdVO1();
    int fetchedRowCount   = coProdVo.getFetchedRowCount();
    Row[] coProdRows      = coProdVo.getAllRowsInRange();
    if ((coProdRows != null) && (coProdRows.length > 0))
    {
      for (int i = 0; i < coProdRows.length; i++)
      {
        row = (OARow)coProdRows[i];
        // 各種情報を取得します。
        qtType = (String)row.getAttribute("QtType");
        // 品質検査有無区分がYの場合
        if (XxwipConstants.QT_TYPE_ON.equals(qtType)) 
        {
          // 各種情報を取得
          Number lotId   = (Number)row.getAttribute("LotId");
          Number itemId  = (Number)row.getAttribute("ItemId");
          Number batchId = (Number)row.getAttribute("BatchId");
          // 品質検査Noを取得する。
          String qtNumber = (String)row.getAttribute("QtNumber");
          String retCode  = null;
          // 品質検査NoがNullの場合
          if (XxcmnUtility.isBlankOrNull(qtNumber)) 
          {
            // 新規
            retCode = XxwipUtility.doQtInspection(
                        getOADBTransaction(),
                        "1",
                        lotId,
                        itemId,
                        batchId,
                        null);
            if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
            {
              warnFlag = true;  
            } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
            {
              exeFlag  = true;
            }
          // 製造日、出来高数が変更された場合
          } else if (!XxcmnUtility.isEquals(bhMakerDate, bhBaseMakerDate)
                  || !XxcmnUtility.isEquals(row.getAttribute("ActualQty"), 
                                            row.getAttribute("BaseActualQty"))) 
          {
            // 更新
            exeType = XxwipUtility.doQtInspection(
                        getOADBTransaction(),
                        "2",
                        lotId,
                        itemId,
                        batchId,
                        qtNumber);
            if (XxcmnConstants.RETURN_WARN.equals(retCode)) 
            {
              warnFlag = true;  
            } else if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
            {
              exeFlag  = true;
            }
          }
        }
      }
    }
    // 正常終了フラグがtrueの場合
    if (exeFlag) 
    {
      exeType = XxcmnConstants.RETURN_SUCCESS;
    // 警告終了フラグがtrueの場合
    } else if (warnFlag)
    {
      exeType = XxcmnConstants.RETURN_WARN;
    }
    return exeType;
  } // doQtInspection

  /***************************************************************************
   * 排他制御チェックを行うメソッドです。
   ***************************************************************************
   */
  public void chkEexclusiveControl()
  {
    String apiName  = "chkEexclusiveControl";
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(gbh.batch_id) cnt "); // バッチID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   gme_batch_header     gbh "); // 生産バッチヘッダ
      sb.append("        ,gme_material_details gmd "); // 生産原料詳細
      sb.append("  WHERE  gbh.batch_id = gmd.batch_id ");
      sb.append("  AND    gmd.material_detail_id = :2 "); // 生産原料詳細ID
      sb.append("  AND    TO_CHAR(gbh.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    TO_CHAR(gmd.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ; ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
      // ヘッダ情報を取得します。
      vo  = getXxwipBatchHeaderVO1();
      row = (OARow)vo.first();
      // 各種情報を取得します。
      String gbhLastUpdateDate = (String)row.getAttribute("GbhLastUpdateDate");// 最終更新日
      String gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate");// 最終更新日
      Number mtlDtlId          = (Number)row.getAttribute("MaterialDetailId");// 生産原料詳細ID 

      //PL/SQLを実行します
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++,  XxcmnUtility.intValue(mtlDtlId));
      cstmt.setString(i++, gbhLastUpdateDate);
      cstmt.setString(i++, gmdLastUpdateDate);
      
      cstmt.execute();
      // 排他エラーの場合
      if (cstmt.getInt(1) == 0) 
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147);
      }
      // 投入品副産物共通 PL/SQLの作成を行います
      sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(gmd.material_detail_id) cnt "); // 生産原料詳細ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   gme_material_details gmd    "); // 生産原料詳細
      sb.append("  WHERE  gmd.material_detail_id = :2 "); // 生産原料詳細ID
      sb.append("  AND    TO_CHAR(gmd.last_update_date, 'YYYY/MM/DD HH24:MI:SS') = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ; ");
      sb.append("END; ");
      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      // 投入情報
      vo  = getXxwipBatchInvestVO1();
      row = (OARow)vo.first();
      int fetchedRowCount = vo.getFetchedRowCount();
      // 更新行取得
      Row[] rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoInvestDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // 各種情報を取得します。
          mtlDtlId   = (Number)row.getAttribute("MaterialDetailId");// 生産原料詳細ID 
          gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate"); // 最終更新日
          //PL/SQLを実行します
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
          cstmt.setString(i++, gmdLastUpdateDate);
      
          cstmt.execute();
          // 排他エラーの場合
          if (cstmt.getInt(1) == 0) 
          {
            XxwipUtility.rollBack(getOADBTransaction(),
                                  XxwipConstants.SAVE_POINT_XXWIP200001J);
            throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN10147);
          }
        }
      }
      // 打込情報
      vo  = getXxwipBatchReInvestVO1();
      row = (OARow)vo.first();
      fetchedRowCount = vo.getFetchedRowCount();
      // 更新行取得
      rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoReInvestDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // 各種情報を取得します。
          mtlDtlId   = (Number)row.getAttribute("MaterialDetailId");// 生産原料詳細ID 
          gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate"); // 最終更新日
          //PL/SQLを実行します
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
          cstmt.setString(i++, gmdLastUpdateDate);
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
      // 副産物情報
      vo  = getXxwipBatchCoProdVO1();
      row = (OARow)vo.first();
      fetchedRowCount = vo.getFetchedRowCount();
      // 更新行取得
      rows = vo.getFilteredRows("ItemNoSwitcher", "ItemNoCoProdDisable");
      if ((rows != null) && (rows.length > 0))
      {
        for (int x = 0; x < rows.length; x++)
        {
          row = (OARow)rows[x];
          // 各種情報を取得します。
          mtlDtlId   = (Number)row.getAttribute("MaterialDetailId");// 生産原料詳細ID 
          gmdLastUpdateDate = (String)row.getAttribute("GmdLastUpdateDate"); // 最終更新日
          //PL/SQLを実行します
          i = 1;
          cstmt.registerOutParameter(i++, Types.INTEGER);
          cstmt.setInt(i++, XxcmnUtility.intValue(mtlDtlId));
          cstmt.setString(i++, gmdLastUpdateDate);
      
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
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
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
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkEexclusiveControl

  /***************************************************************************
   * バッチに紐付く処理日付を更新します。
   * @param batchId - バッチID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void changeTransDateAll(
    Number batchId
    ) throws OAException
  {
    String apiName = "changeTransDateAll";

    // PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(500);
    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.change_trans_date_all ( ");
    sb.append("    in_batch_id => :1 ");
    sb.append("   ,ov_errbuf   => :2 ");
    sb.append("   ,ov_retcode  => :3 ");
    sb.append("   ,ov_errmsg   => :4 ");
    sb.append("  ); ");
    sb.append("END; ");

    // PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++,  XxcmnUtility.intValue(batchId)); // バッチID
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 1); 
      cstmt.registerOutParameter(i++, Types.VARCHAR, 5000); 
     
      // PL/SQL実行
      cstmt.execute();

      if (!XxcmnConstants.API_RETURN_NORMAL.equals(cstmt.getString(3))) 
      {
        // ロールバック
        doRollBack();
        // APIエラーを出力する。
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              cstmt.getString(2) + cstmt.getString(4),
                              6);
        //トークンを生成します。
        MessageToken[] tokens = { new MessageToken(XxwipConstants.TOKEN_API_NAME,
                                                   "処理日付更新関数") };
        throw new OAException(XxcmnConstants.APPL_XXWIP, 
                              XxwipConstants.XXWIP10049, 
                              tokens);
      }
    // PL/SQL実行時例外の場合
    } catch (SQLException s)
    {
      // ロールバック
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
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
      } catch (SQLException s)
      {
        // ロールバック
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // changeTransDateAll 

  /*****************************************************************************
   * 引当数量チェックを行います。
   * @return String - 警告メッセージ
   ****************************************************************************/
  public String checkLotQty()
  {
    boolean exeFlag = false;
    boolean makerDateChangeFlag = false; // 製造日変更フラグ
    // ダイアログ画面表示用メッセージ
    StringBuffer dialogMsg = new StringBuffer(100);

    // バッチヘッダ情報VO取得
    XxwipBatchHeaderVOImpl hdrVo  = getXxwipBatchHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

    // 各種情報取得
    String lotNo         = (String)hdrRow.getAttribute("LotNo");             // ロットNo
    Date makerDate       = (Date)hdrRow.getAttribute("MakerDate");           // 製造日
    Date baseMakerDate   = (Date)hdrRow.getAttribute("BaseMakerDate");       // 製造日(DB)
    Number batchId       = (Number)hdrRow.getAttribute("BatchId");           // バッチID
    Number itemId        = (Number)hdrRow.getAttribute("ItemId");            // 品目ID
    Number lotId         = (Number)hdrRow.getAttribute("LotId");             // ロットID
    Number invLocId      = (Number)hdrRow.getAttribute("InventoryLocationId");// 保管場所ID
    String itemClassCode = (String)hdrRow.getAttribute("ItemClassCode");     // 品目区分
    String actualQty     = (String)hdrRow.getAttribute("ActualQty");         // 実績数量
    String baseActualQty = (String)hdrRow.getAttribute("BaseActualQty");     // 実績数量(DB)
    String locName       = (String)hdrRow.getAttribute("DeliveryLocationName");

    // 品目区分が「5:製品」で、製造日が変更された場合
    if ( XxcmnUtility.isEquals(itemClassCode, XxwipConstants.ITEM_TYPE_PROD)
     && !XxcmnUtility.isEquals(makerDate,     baseMakerDate)) 
    {
      // 製造日変更フラグをtrueにする
      makerDateChangeFlag = true;
      actualQty = XxcmnConstants.STRING_ZERO;
    }
    /****************************
     * 完成品の場合
     ****************************/
    // 出来高総数が減数変更された場合
    if (makerDateChangeFlag 
     || XxcmnUtility.chkCompareNumeric(1, baseActualQty, actualQty)) 
    {
      // 引当数量チェック関数で警告だった場合
      if (XxcmnConstants.API_RETURN_WARN.equals(XxwipUtility.chkReservedQuantity(
                                                  getOADBTransaction(),
                                                  itemId,
                                                  lotId,
                                                  invLocId,
                                                  baseMakerDate,
                                                  actualQty,
                                                  baseActualQty))) 
      {
        // トークン生成
        String itemName = (String)hdrRow.getAttribute("ItemName");
        MessageToken[] tokens = new MessageToken[3];
        tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, locName);  // 納品場所名称
        tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     itemName); // 品目名称
        tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      lotNo);    // ロットNo
        
        // メインメッセージ作成
        dialogMsg.append(getOADBTransaction().getMessage(XxcmnConstants.APPL_XXCMN, 
                                                         XxcmnConstants.XXCMN10112,
                                                         tokens));
      }
    }
    /****************************
     * 副産物の場合
     ****************************/
    // 副産物情報VO取得
    XxwipBatchCoProdVOImpl vo  = getXxwipBatchCoProdVO1();
    OARow row = (OARow)vo.first();
    Row[] coProdRows = vo.getAllRowsInRange();
    if ((coProdRows != null) && (coProdRows.length > 0))
    {
      for (int i = 0; i < coProdRows.length; i++)
      {
        row = (OARow)coProdRows[i];
        Number coProdItemId        = (Number)row.getAttribute("ItemId");       // 品目ID
        Number coProdLotId         = (Number)row.getAttribute("LotId");        // ロットID
        String coProdActualQty     = (String)row.getAttribute("ActualQty");    // 実績数量
        String coProdBaseActualQty = (String)row.getAttribute("BaseActualQty");// 実績数量(DB)
        // 実績総数が減数変更された場合
        if (makerDateChangeFlag 
         || XxcmnUtility.chkCompareNumeric(1, coProdBaseActualQty, coProdActualQty))
        {
          // 製造日が変更された場合
          if (makerDateChangeFlag) 
          {
            coProdActualQty = XxcmnConstants.STRING_ZERO;
          }
          // 引当数量チェック関数で警告だった場合
          if (XxcmnConstants.API_RETURN_WARN.equals(XxwipUtility.chkReservedQuantity(
                                                      getOADBTransaction(),
                                                      coProdItemId,
                                                      coProdLotId,
                                                      invLocId,
                                                      baseMakerDate,
                                                      coProdActualQty,
                                                      coProdBaseActualQty))) 
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(dialogMsg);
            // トークン生成
            String itemName = (String)row.getAttribute("ItemName");
            MessageToken[] tokens = new MessageToken[3];
            tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, locName);  // 納品場所名称
            tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     itemName); // 品目名称
            tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      lotNo);    // ロットNo
        
            // メインメッセージ作成
            dialogMsg.append(getOADBTransaction().getMessage(XxcmnConstants.APPL_XXCMN, 
                                                             XxcmnConstants.XXCMN10112,
                                                             tokens));
          }
        }
      }
    }
    return dialogMsg.toString();
  } // lotExecute

  /***************************************************************************
   * 検査依頼Noの取得を行うメソッドです。
   * @param itemId  - 品目ID
   * @param lotId   - ロットID
   * @return String - 検査依頼No
   ***************************************************************************
   */
  public String getQtNumber(
    Number itemId,
    Number lotId)
  {
    String apiName  = "getQtNumber";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQLの作成を行います
      StringBuffer sb = new StringBuffer(500);
      sb.append("DECLARE ");
      sb.append("  lv_qt_number VARCHAR2(10);   ");
      sb.append("BEGIN ");
      sb.append("  SELECT TO_CHAR(xqi.qt_inspect_req_no) "); // 品質検査依頼No
      sb.append("  INTO   lv_qt_number ");
      sb.append("  FROM   xxwip_qt_inspection  xqi "); // 品質検査依頼情報アドオン
      sb.append("  WHERE  xqi.lot_id  = :1 "); // ロットID
      sb.append("  AND    xqi.item_id = :2 "); // 品目ID
      sb.append("  AND    ROWNUM      = 1  ");
      sb.append("  ; ");
      sb.append("    :3 := lv_qt_number;  ");
      sb.append("EXCEPTION ");
      sb.append("  WHEN NO_DATA_FOUND THEN "); // データがない場合は0
      sb.append("    :3 := null; ");
      sb.append("END; ");

      //PL/SQLの設定を行います
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQLを実行します
      int i = 1;
      cstmt.setInt(i++,  XxcmnUtility.intValue(lotId));
      cstmt.setInt(i++,  XxcmnUtility.intValue(itemId));
      cstmt.registerOutParameter(i++, Types.VARCHAR);
      
      cstmt.execute();

      return cstmt.getString(3);

    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
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
                              XxwipConstants.CLASS_AM_XXWIP200001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getQtNumber

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
   * Container's getter for XxwipBatchInvestVO1
   */
  public XxwipBatchInvestVOImpl getXxwipBatchInvestVO1()
  {
    return (XxwipBatchInvestVOImpl)findViewObject("XxwipBatchInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchHeaderVO1
   */
  public XxwipBatchHeaderVOImpl getXxwipBatchHeaderVO1()
  {
    return (XxwipBatchHeaderVOImpl)findViewObject("XxwipBatchHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchReInvestVO1
   */
  public XxwipBatchReInvestVOImpl getXxwipBatchReInvestVO1()
  {
    return (XxwipBatchReInvestVOImpl)findViewObject("XxwipBatchReInvestVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchCoProdVO1
   */
  public XxwipBatchCoProdVOImpl getXxwipBatchCoProdVO1()
  {
    return (XxwipBatchCoProdVOImpl)findViewObject("XxwipBatchCoProdVO1");
  }

  /**
   * 
   * Container's getter for SlitVO1
   */
  public SlitVOImpl getSlitVO1()
  {
    return (SlitVOImpl)findViewObject("SlitVO1");
  }

  /**
   * 
   * Container's getter for XxwipVolumeActualPVO1
   */
  public XxwipVolumeActualPVOImpl getXxwipVolumeActualPVO1()
  {
    return (XxwipVolumeActualPVOImpl)findViewObject("XxwipVolumeActualPVO1");
  }

  /**
   * 
   * Container's getter for XxwipBatchTotalVO1
   */
  public XxwipBatchTotalVOImpl getXxwipBatchTotalVO1()
  {
    return (XxwipBatchTotalVOImpl)findViewObject("XxwipBatchTotalVO1");
  }
}