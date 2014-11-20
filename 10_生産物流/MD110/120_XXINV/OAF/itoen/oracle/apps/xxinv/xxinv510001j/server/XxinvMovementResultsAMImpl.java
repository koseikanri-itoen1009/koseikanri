/*============================================================================
* ファイル名 : XxinvMovementResultsAMImpl
* 概要説明   : 入出庫実績要約:検索アプリケーションモジュール
* バージョン : 1.15
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-12 1.0  大橋孝郎     新規作成
* 2008-06-11 1.2  大橋孝郎     不具合指摘事項修正
* 2008-06-18 1.3  大橋孝郎     不具合指摘事項修正
* 2008-06-26 1.4  伊藤ひとみ   ST#296対応
* 2008-07-25 1.5  山本恭久     不具合指摘事項修正
* 2008-08-20 1.6  山本恭久     ST#249対応、内部変更#167対応
* 2008-09-24 1.7  伊藤ひとみ   統合テスト 指摘59,156対応
* 2008-10-21 1.8  伊藤ひとみ   統合テスト 指摘353対応
* 2008-12-01 1.9  伊藤ひとみ   本番障害#236対応
* 2008-12-25 1.10 伊藤ひとみ   本番障害#797,821対応
* 2009-02-09 1.11 伊藤ひとみ   本番障害#1143対応
* 2009-02-26 1.12 二瓶大輔     本番障害#885対応
* 2009-03-11 1.13 伊藤ひとみ   本番障害#885対応(再対応)
* 2009-06-18 1.14 伊藤ひとみ   本番障害#1314対応
* 2009-12-28 1.15 伊藤ひとみ   本稼動障害#695
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.server;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.common.MessageToken;
import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxinv.util.XxinvUtility;

import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 入出庫実績要約:検索アプリケーションモジュールです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.15
 ***************************************************************************
 */
public class XxinvMovementResultsAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementResultsAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxinv.xxinv510001j.server", "XxinvMovementResultsAMLocal");
  }

  /***************************************************************************
   * 入出庫実績要約画面の初期化処理を行うメソッドです。
   * @param searchParams - パラメータHashMap
   ***************************************************************************
   */
  public void initialize(
    HashMap searchParams
  )
  {
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();

    String actualFlag  = (String)searchParams.get("actualFlag");    // 実績データ区分
    String productFlag = (String)searchParams.get("productFlag");   // 製品識別区分

    // 1行もない場合、空行作成
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1行目を取得
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      // キーに値をセット
      resultsSearchRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchRow.setAttribute("RowKey", new Number(1));
      resultsSearchRow.setAttribute("ActualFlg",  actualFlag);
      resultsSearchRow.setAttribute("ProductFlg", productFlag);
    }

    // ******************************* //
    // *     ユーザー情報取得        * //
    // ******************************* //
    getUserData(actualFlag, "1");

  } // initialize

  /***************************************************************************
   * ユーザー情報を取得するメソッドです。
   * @param actualFlag 実績データ区分
   * @param exeType    起動画面(要約画面:1、ヘッダ画面:2)
   ***************************************************************************
   */
  public void getUserData(
    String actualFlag,
    String exeType
  )
  {
    // ユーザー情報取得
    HashMap paramsRet = XxinvUtility.getUserData(
                            getOADBTransaction()  // トランザクション
                            );

    // 入力実績要約VO取得
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1行目を取得
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();

    // 従業員区分をセット
    resultsSearchRow.setAttribute("PeopleCode", paramsRet.get("retpeopleCode"));

    // 外部ユーザの場合
    if (XxinvConstants.PEOPLE_CODE_O.equals(paramsRet.get("retpeopleCode")))
    {
      // 出庫実績メニューから起動
      if (XxinvConstants.ACTUAL_FLAG_DELI.equals(actualFlag))
      {
        // 保管場所がセット済みの場合
        if ("2".equals(exeType))
        {
          // 入出庫実績ヘッダVO取得
          OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
          // 1行目を取得
          OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
          // 保管場所をセット
          movementResultsHdRow.setAttribute("ShippedLocatId",   paramsRet.get("locationId"));
          movementResultsHdRow.setAttribute("ShippedLocatCode", paramsRet.get("locationsCode"));
          movementResultsHdRow.setAttribute("Description1",     paramsRet.get("locationsName"));
        } else if ("1".equals(exeType))
        {
          // 保管場所をセット
          resultsSearchRow.setAttribute("ShipLcationCode",  paramsRet.get("locationsCode"));
          resultsSearchRow.setAttribute("ShipLocationName", paramsRet.get("locationsName"));
          resultsSearchRow.setAttribute("ShipLocationId",   paramsRet.get("locationId"));
        }

      // 入庫実績メニューから起動
      } else if (XxinvConstants.ACTUAL_FLAG_SCOC.equals(actualFlag))
      {
        // 保管場所がセット済みの場合
        if ("2".equals(exeType))
        {
          // 入出庫実績ヘッダVO取得
          OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
          // 1行目を取得
          OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
          // 保管場所をセット
          movementResultsHdRow.setAttribute("ShipToLocatId",   paramsRet.get("locationId"));
          movementResultsHdRow.setAttribute("ShipToLocatCode", paramsRet.get("locationsCode"));
          movementResultsHdRow.setAttribute("Description2",    paramsRet.get("locationsName"));
        } else if ("1".equals(exeType))
        {
          // 保管場所をセット
          resultsSearchRow.setAttribute("ArrivalLocationCode", paramsRet.get("locationsCode"));
          resultsSearchRow.setAttribute("ArrivalLocationName", paramsRet.get("locationsName"));
          resultsSearchRow.setAttribute("ArrivalLocationId",   paramsRet.get("locationId"));
        }
      }
    }

  } // getUserData

  /***************************************************************************
   * 入出庫実績要約画面の検索処理を行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  )
  {
    // 移動実績情報VO取得
    XxinvMovementResultsVOImpl xxinvMovementResultsVo = getXxinvMovementResultsVO1();
    // 検索
    String shippedLocatId = (String)searchParams.get("shippedLocatId");

    xxinvMovementResultsVo.initQuery(searchParams); // 検索パラメータ用HashMap

    // 1行目を取得
    OARow row = (OARow)xxinvMovementResultsVo.first();
    
  } // doSearch

  /***************************************************************************
   * 入出庫実績要約画面の出庫日Fromのコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyShipDate()
  {
    // 移動実績情報VO取得
    OAViewObject vo    = getXxinvMovResultsSearchVO1();
    OARow row          = (OARow)vo.first();
    Date  shipDateFrom = (Date)row.getAttribute("ShipDateFrom");
    Date  shipDateTo   = (Date)row.getAttribute("ShipDateTo");

    // 出庫日ToがNullの場合、出庫日Fromをコピー
    if (XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      row.setAttribute("ShipDateTo", shipDateFrom);
    }
  } // copyShipDate

  /****************************************************************************
   * 入出庫実績要約画面の着日Fromのコピー処理を行うメソッドです。
   ****************************************************************************
   */
  public void copyArrivalDate()
  {
    // 移動実績情報VO取得
    OAViewObject vo       = getXxinvMovResultsSearchVO1();
    OARow row             = (OARow)vo.first();
    Date  arrivalDateFrom = (Date)row.getAttribute("ArrivalDateFrom");
    Date  arrivalDateTo   = (Date)row.getAttribute("ArrivalDateTo");

    // 着日ToがNullの場合、着日Fromをコピー
    if (XxcmnUtility.isBlankOrNull(arrivalDateTo))
    {
      row.setAttribute("ArrivalDateTo", arrivalDateFrom);
    }
  } // copyArrivalDate

  /***************************************************************************
   * 入出庫実績要約画面の検索項目未指定チェックを行うメソッドです。
   * @param searchParams 検索パラメータ用HashMap
   ***************************************************************************
   */
  public void doItemCheck(
    HashMap searchParams
  )
  {
    // 入力項目数
    int itemCount = 0;
    
    // 検索条件取得
    String movNum              = (String)searchParams.get("movNum");              // 移動番号
    String movType             = (String)searchParams.get("movType");             // 移動タイプ
    String status              = (String)searchParams.get("status");              // ステータス
    String shippedLocatId      = (String)searchParams.get("shippedLocatId");      // 出庫元
    String shipToLocatId       = (String)searchParams.get("shipToLocatId");       // 入庫先
    String shipDateFrom        = (String)searchParams.get("shipDateFrom");        // 出庫日(開始)
    String shipDateTo          = (String)searchParams.get("shipDateTo");          // 出庫日(終了)
    String arrivalDateFrom     = (String)searchParams.get("arrivalDateFrom");     // 着日(開始)
    String arrivalDateTo       = (String)searchParams.get("arrivalDateTo");       // 着日(終了)
    String instructionPostCode = (String)searchParams.get("instructionPostCode"); // 移動指示部署
    String deliveryNo          = (String)searchParams.get("deliveryNo");          // 配送No

    // 移動番号
    if (!XxcmnUtility.isBlankOrNull(movNum))
    {
      itemCount = itemCount + 1;
    }
    // 移動タイプ
    if (!XxcmnUtility.isBlankOrNull(movType))
    {
      itemCount = itemCount + 1;
    }
    // ステータス
    if (!XxcmnUtility.isBlankOrNull(status))
    {
      itemCount = itemCount + 1;
    }
    // 出庫元
    if (!XxcmnUtility.isBlankOrNull(shippedLocatId))
    {
      itemCount = itemCount + 1;
    }
    // 入庫先
    if (!XxcmnUtility.isBlankOrNull(shipToLocatId))
    {
      itemCount = itemCount + 1;
    }
    // 出庫日(開始)
    if (!XxcmnUtility.isBlankOrNull(shipDateFrom))
    {
      itemCount = itemCount + 1;
    }
    // 出庫日(終了)
    if (!XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      itemCount = itemCount + 1;
    }
    // 着日(開始)
    if (!XxcmnUtility.isBlankOrNull(arrivalDateFrom))
    {
      itemCount = itemCount + 1;
    }
    // 着日(終了)
    if (!XxcmnUtility.isBlankOrNull(arrivalDateTo))
    {
      itemCount = itemCount + 1;
    }
    // 移動指示部署
    if (!XxcmnUtility.isBlankOrNull(instructionPostCode))
    {
      itemCount = itemCount + 1;
    }
    // 配送No
    if (!XxcmnUtility.isBlankOrNull(deliveryNo))
    {
      itemCount = itemCount + 1;
    }
    // 検索条件が全て未入力の場合
    if (itemCount == 0)
    {
      // エラーメッセージ出力
      throw new OAException(
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10043);
    }
  } // doItemCheck

  /***************************************************************************
   * 入出庫実績ヘッダ画面の摘要ボタンの無効切替制御を行うメソッドです。
   * @param flag - 0:有効
   *              - 1:無効
   ***************************************************************************
   */
  public void disabledChanged(
    String flag
  )
  {
    // 入出庫実績ヘッダ:登録:登録PVO取得
    OAViewObject movementResultsHdPvo = getXxinvMovementResultsHdPVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)movementResultsHdPvo.first();

    // フラグが0:有効の場合
    if ("0".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled", Boolean.FALSE); // 適用ボタン押下可

    // フラグが1:無効の場合
    } else if ("1".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled", Boolean.TRUE); // 適用ボタン押下不可
    }
  } // disabledChanged

  /***************************************************************************
   * 入出庫実績ヘッダ画面の入力制御を行うメソッドです。
   * @param peocessFlag 処理フラグ
   ***************************************************************************
   */
  public void readOnlyChanged(String peocessFlag)
  {
    // 入出庫実績ヘッダ:登録PVO取得
    OAViewObject resultsHdrPVO = getXxinvMovementResultsHdPVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)resultsHdrPVO.first();

    // 処理フラグ:1(登録)の場合
    if ("1".equals(peocessFlag))
    {
      // 入出庫実績ヘッダ:検索VO取得
      OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
      // 1行目を取得
      OARow searchVoRow = (OARow)resultsSearchVo.first();
      
    // mod start ver1.5
      // 製品識別区分:2(製品以外)の場合
//      if ("2".equals(searchVoRow.getAttribute("ProductFlg")))
//      {
        // ヘッダ.運送業者を読取専用に変更
//        readOnlyRow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE);
//      }
    // mod end ver1.5
      // ヘッダ.修正フラグを読取専用に変更
      readOnlyRow.setAttribute("NewModifyFlgReadOnly", Boolean.TRUE);
      // ヘッダ.移動タイプを読取専用に変更
      readOnlyRow.setAttribute("MovTypeReadOnly",      Boolean.TRUE);

    // 処理フラグ:2(更新)の場合
    } else if ("2".equals(peocessFlag))
    {
      // 入出庫実績ヘッダ:登録VO取得
      OAViewObject resultsHdrVO = getXxinvMovementResultsHdVO1();
      // 1行目を取得
      OARow row = (OARow)resultsHdrVO.first();
      String deliveryNo = (String)row.getAttribute("DeliveryNo");
      
      // ヘッダ.移動指示部署を読取専用に変更
      readOnlyRow.setAttribute("InstructionPostReadOnly", Boolean.TRUE);
      // ヘッダ.移動タイプを読取専用に変更
      readOnlyRow.setAttribute("MovTypeReadOnly",         Boolean.TRUE);
      // ヘッダ.修正フラグを読取専用に変更
      readOnlyRow.setAttribute("NewModifyFlgReadOnly",    Boolean.TRUE);
      // ヘッダ.出庫元を読取専用に変更
      readOnlyRow.setAttribute("ShippedLocatReadOnly",    Boolean.TRUE);
      // ヘッダ.入庫先を読取専用に変更
      readOnlyRow.setAttribute("ShipToLocatReadOnly",     Boolean.TRUE);
      // 配送Noが付与されていた場合
      if (!XxcmnUtility.isBlankOrNull(deliveryNo))
      {
        // ヘッダ.出庫日(実績)を読取専用に変更
        readOnlyRow.setAttribute("ActualShipDateReadOnly",    Boolean.TRUE);
        // ヘッダ.着日(実績)を読取専用に変更
        readOnlyRow.setAttribute("ActualArrivalDateReadOnly", Boolean.TRUE);
      } else
      {
        // ヘッダ.出庫日(実績)を読取専用に変更
        readOnlyRow.setAttribute("ActualShipDateReadOnly",    Boolean.FALSE);
        // ヘッダ.着日(実績)を読取専用に変更
        readOnlyRow.setAttribute("ActualArrivalDateReadOnly", Boolean.FALSE);
      }
      // ヘッダ.運賃区分を読取専用に変更
      readOnlyRow.setAttribute("FreightChargeClassReadOnly",  Boolean.TRUE);
      // ヘッダ.運送業者を読取専用に変更
      readOnlyRow.setAttribute("FreightCarrierReadOnly",      Boolean.TRUE);
      // ヘッダ.時間指定Fromを読取専用に変更
      readOnlyRow.setAttribute("ArrivalTimeFromReadOnly",     Boolean.TRUE);
      // ヘッダ.時間指定Toを読取専用に変更
      readOnlyRow.setAttribute("ArrivalTimeToReadOnly",       Boolean.TRUE);
      // ヘッダ.パレット回収枚数を読取専用に変更
      readOnlyRow.setAttribute("CollectedPalletReadOnly",     Boolean.TRUE);
      // ヘッダ.契約外運賃区分を読取専用に変更
      readOnlyRow.setAttribute("NoContFreightClassReadOnly",  Boolean.TRUE);
      // ヘッダ.重量容積区分を読取専用に変更
      readOnlyRow.setAttribute("WeightCapacityClassReadOnly", Boolean.TRUE);
      // ヘッダ.摘要を読取専用に変更
      readOnlyRow.setAttribute("DescriptionReadOnly",         Boolean.TRUE);
      
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
      String compActualFlg     = (String)row.getAttribute("CompActualFlg");   // 実績計上済フラグ
      Date   actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // 出庫実績日
      Date   actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // 入庫実績日

      // 実績計上済で出庫実績日がクローズしている場合
      if  (XxcmnConstants.STRING_Y.equals(compActualFlg)
        && XxinvUtility.chkStockClose(getOADBTransaction(), actualShipDate))
      {
        // 参照のみ。
        readOnlyRow.setAttribute("ActualShipDateReadOnly",    Boolean.TRUE); // 出庫日(実績)：読取専用
        readOnlyRow.setAttribute("ActualArrivalDateReadOnly", Boolean.TRUE); // 着日(実績)：読取専用
        readOnlyRow.setAttribute("OutPalletReadOnly",         Boolean.TRUE); // パレット枚数(出)：読取専用
        readOnlyRow.setAttribute("InPalletReadOnly",          Boolean.TRUE); // パレット枚数(入)：読取専用
        disabledChanged("1"); // 適用を無効に設定
      }
// 2008-10-21 H.Itou Add End
    }
  } // readOnlyChanged

  /***************************************************************************
   * 入出庫実績ヘッダ画面の初期化処理を行うメソッドです。
   * @param searchParams - パラメータHashMap
   ***************************************************************************
   */
  public void initializeHdr(
    HashMap searchParams
  )
  {
    // パラメータ取得
    String peopleCode  = (String)searchParams.get(XxinvConstants.URL_PARAM_PEOPLE_CODE);
    String actualFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_ACTUAL_FLAG);
    String productFlag = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);
    String itemClass   = (String)searchParams.get(XxinvConstants.URL_PARAM_ITEM_CLASS);
    String updateFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_UPDATE_FLAG);

    // ************************************* //
    // *    入出庫実績:検索VO 空行取得     * //
    // ************************************* //
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1行もない場合、空行作成
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1行目を取得
      OARow resultsSearchVoRow = (OARow)resultsSearchVo.first();
      // キーに値をセット
      resultsSearchVoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchVoRow.setAttribute("RowKey", new Number(1));
      resultsSearchVoRow.setAttribute("PeopleCode", peopleCode);
      resultsSearchVoRow.setAttribute("ActualFlg",  actualFlag);
      resultsSearchVoRow.setAttribute("ProductFlg", productFlag);
      resultsSearchVoRow.setAttribute("UpdateFlag", updateFlag);
    }

    // ******************************************* //
    // *    入出庫実績:検索ヘッダVO 空行取得     * //
    // ******************************************* //
    OAViewObject resultsSearchHdVo = getXxinvMovResultsHdSearchVO1();
    // 1行もない場合、空行作成
    if (!resultsSearchHdVo.isPreparedForExecution())
    {
      resultsSearchHdVo.setMaxFetchSize(0);
      resultsSearchHdVo.insertRow(resultsSearchHdVo.createRow());
      // 1行目を取得
      OARow resultsSearchHdVoRow = (OARow)resultsSearchHdVo.first();
      // キーに値をセット
      resultsSearchHdVoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchHdVoRow.setAttribute("RowKey", new Number(1));
    }

    // ************************************* //
    // * 入出庫実績ヘッダ:登録VO 空行取得  * //
    // ************************************* //
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1行もない場合、空行作成
    if (!movementResultsHdVo.isPreparedForExecution())
    {
      movementResultsHdVo.setWhereClauseParam(0,null);
      movementResultsHdVo.executeQuery();
      movementResultsHdVo.insertRow(movementResultsHdVo.createRow());
      // 1行目を取得
      OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
      // キーに値をセット
      movementResultsHdRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsHdRow.setAttribute("MovType",         XxinvConstants.MOV_TYPE_1);
      movementResultsHdRow.setAttribute("NotifStatus",     XxinvConstants.NOTIFSTATSU_CODE_1O);
      movementResultsHdRow.setAttribute("NotifStatusName", XxinvConstants.NOTIFSTATSU_NAME_1O);

      // 製品識別区分が:1(製品)の場合
      if ("1".equals(productFlag))
      {
        movementResultsHdRow.setAttribute("FreightChargeClass", XxinvConstants.FREIGHT_CHARGE_CLASS_1);
      } else if ("2".equals(productFlag))
      {
        movementResultsHdRow.setAttribute("FreightChargeClass", XxinvConstants.FREIGHT_CHARGE_CLASS_0);
      }

      // 商品区分が:1リーフの場合
      if ("1".equals(itemClass))
      {
        movementResultsHdRow.setAttribute("WeightCapacityClass",     XxinvConstants.WEIGHT_CAPACITY_CLASS_CODE_2);
        movementResultsHdRow.setAttribute("WeightCapacityClassName", XxinvConstants.WEIGHT_CAPACITY_CLASS_NAME_2);

      // 商品区分が:2ドリンクの場合
      } else if ("2".equals(itemClass))
      {
        movementResultsHdRow.setAttribute("WeightCapacityClass",     XxinvConstants.WEIGHT_CAPACITY_CLASS_CODE_1);
        movementResultsHdRow.setAttribute("WeightCapacityClassName", XxinvConstants.WEIGHT_CAPACITY_CLASS_NAME_1);
      }

      // 更新フラグがNULLの場合
      if (XxcmnUtility.isBlankOrNull(updateFlag))
      {
        // 処理フラグ 1:登録
        movementResultsHdRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_I);
        // ユーザ情報取得
        getUserData(actualFlag, "2");
      } else
      {
        // 処理フラグ 2:更新
        movementResultsHdRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_U);
      }
    }

    // ************************************* //
    // * 入出庫実績ヘッダ:登録PVO 空行取得 * //
    // ************************************* //
    OAViewObject movementResultsHdPvo = getXxinvMovementResultsHdPVO1();
    // 1行もない場合、空行作成
    if (!movementResultsHdPvo.isPreparedForExecution())
    {
      movementResultsHdPvo.setMaxFetchSize(0);
      movementResultsHdPvo.insertRow(movementResultsHdPvo.createRow());
      // 1行目を取得
      OARow movementResultsHdPvoRow = (OARow)movementResultsHdPvo.first();
      // キーに値をセット
      movementResultsHdPvoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsHdPvoRow.setAttribute("RowKey", new Number(1));
    }
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
    // ************************************* //
    // * 入出庫実績明細:PVO 空行取得       * //
    // ************************************* //
    OAViewObject movementResultsLnPvo = getXxinvMovementResultsLnPVO1();
    // 1行もない場合、空行作成
    if (!movementResultsLnPvo.isPreparedForExecution())
    {
      movementResultsLnPvo.setMaxFetchSize(0);
      movementResultsLnPvo.insertRow(movementResultsLnPvo.createRow());
      // 1行目を取得
      OARow movementResultsLnPvoRow = (OARow)movementResultsLnPvo.first();
      // キーに値をセット
      movementResultsLnPvoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsLnPvoRow.setAttribute("RowKey", new Number(1));
    }
// 2008-10-21 H.Itou Add End
     
  } // initializeHdr

  /***************************************************************************
   * 入出庫実績ヘッダ画面の新規行挿入処理を行うメソッドです。
   ***************************************************************************
   */
  public void addRow()
  {
    //入出庫実績ヘッダ:登録VO取得
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();

    // *********************** //
    // *  無効切替処理       * //
    // *********************** //
    // 処理フラグ 1:登録の場合
    if (movementResultsHdRow.getAttribute("ProcessFlag").equals(XxinvConstants.PROCESS_FLAG_I))
    {
      disabledChanged("1"); // 適用を無効に設定
    } else
    {
      disabledChanged("0"); // 適用を有効に設定
    }

    // *********************** //
    // *  入力制御処理       * //
    // *********************** //
    readOnlyChanged("1");
     
  } // addRow

  /***************************************************************************
   * 入出庫実績ヘッダ画面の検索処理を行うメソッドです。
   * @param searchHdrId  - 検索パラメータヘッダID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchHdr(String searchHdrId) throws OAException
  {
    // 入出庫実績ヘッダ:登録VO取得
    XxinvMovementResultsHdVOImpl movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 検索
    movementResultsHdVo.initQuery(searchHdrId);         // 検索パラメータヘッダID
    // 1行めを取得
    OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();

    // データを取得できなかった場合
    if (movementResultsHdVo.getRowCount() == 0)
    {
      // *********************** //
      // *  VO初期化処理       * //
      // *********************** //
      OAViewObject vo = getXxinvMovementResultsHdVO1();
      vo.setWhereClauseParam(0,null);
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      // 1行目を取得
      OARow row = (OARow)vo.first();
      // キーに値をセット
      row.setNewRowState(Row.STATUS_INITIALIZED);
      row.setAttribute("MovHdrId", new Number(-1));
      row.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_I);

      // *********************** //
      // *  無効切替処理       * //
      // *********************** //
      disabledChanged("1"); // 適用を無効に設定

      // ************************ //
      // * エラーメッセージ出力 *
      // ************************ //
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);

    // データを取得できた場合
    } else
    { 

      movementResultsHdRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_U); // 処理フラグ 2:更新
      // 出庫日(実績)、着日(実績)をセット
      OAViewObject searchVo = getXxinvMovResultsSearchVO1();
      OARow searchVoRow = (OARow)searchVo.first();

      // 配送Noが付与されている場合
      if (!XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("DeliveryNo")))
      {
        // 出庫日(実績)がNULLの場合
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualShipDate")))
        {
          // 出庫日を出庫日(実績)へセットする
          movementResultsHdRow.setAttribute("ActualShipDate", movementResultsHdRow.getAttribute("ScheduleShipDate"));
        }
        // 着日(実績)がNULLの場合
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualArrivalDate")))
        {
          // 着日を着日(実績)へセットする
          movementResultsHdRow.setAttribute("ActualArrivalDate", movementResultsHdRow.getAttribute("ScheduleArrivalDate"));
        }
// 2008-09-24 H.Itou add Start 統合テスト指摘59 出庫実績日がない場合、出庫予定日を出庫実績日に表示する。
      // 配送Noがない場合
      } else
      { 
        String actualFlg = (String)searchVoRow.getAttribute("ActualFlg"); // 実績データ区分

        // 出庫実績メニューで起動の場合で、出庫日(実績)がNULLの場合、出庫予定日をコピー
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualShipDate"))
         && XxinvConstants.ACTUAL_FLAG_DELI.equals(actualFlg))
        {
          // 出庫日を出庫日(実績)へセットする
          movementResultsHdRow.setAttribute("ActualShipDate", movementResultsHdRow.getAttribute("ScheduleShipDate"));
        }
        // 入庫実績メニューで起動の場合で、着日(実績)がNULLの場合、着荷予定日をコピー
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualArrivalDate"))
         && XxinvConstants.ACTUAL_FLAG_SCOC.equals(actualFlg))
        {
          // 着日を着日(実績)へセットする
          movementResultsHdRow.setAttribute("ActualArrivalDate", movementResultsHdRow.getAttribute("ScheduleArrivalDate"));
        }
// 2008-09-24 H.Itou add End
      }

      searchVoRow.setAttribute("ActualShipDate",    movementResultsHdRow.getAttribute("ActualShipDate"));
      searchVoRow.setAttribute("ActualArrivalDate", movementResultsHdRow.getAttribute("ActualArrivalDate"));
      // 移動指示部署、出庫元、入庫先、運送業者の名称をセット
      OAViewObject searchHdVo = getXxinvMovResultsHdSearchVO1();
      OARow searchHdVoRow = (OARow)searchHdVo.first();
      searchHdVoRow.setAttribute("LocationName",        movementResultsHdRow.getAttribute("LocationShortName"));
      searchHdVoRow.setAttribute("ShipLocationName",    movementResultsHdRow.getAttribute("Description1"));
      searchHdVoRow.setAttribute("ArrivalLocationName", movementResultsHdRow.getAttribute("Description2"));
      searchHdVoRow.setAttribute("FrtCarrierName",      movementResultsHdRow.getAttribute("PartyName2"));

      // *********************** //
      // *  無効切替処理       * //
      // *********************** //
      disabledChanged("0"); // 適用を有効に設定

      // *********************** //
      // *  入力制御処理       * //
      // *********************** //
      readOnlyChanged("2");
    }
  } // doSearchHdr

  /***************************************************************************
   * 入出庫実績ヘッダ画面の出庫日(実績)のコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyActualShipDate()
  {
    // 移動実績情報VO取得
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow row = (OARow)vo.first();
    Date  actualShipDate = (Date)row.getAttribute("ActualShipDate");

    // 出庫日(実績)を出庫日にコピー
    row.setAttribute("ScheduleShipDate", actualShipDate);
    
  } // copyActualShipDate

  /***************************************************************************
   * 入出庫実績ヘッダ画面の着日(実績)のコピー処理を行うメソッドです。
   ***************************************************************************
   */
  public void copyActualArrivalDate()
  {
    // 移動実績情報VO取得
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow row = (OARow)vo.first();
    Date  actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate");

    // 着日(実績)を着日にコピー
    row.setAttribute("ScheduleArrivalDate", actualArrivalDate);
    
  } // copyActualArrivalDate

  /***************************************************************************
   * 運送業者項目を入力可能にするメソッドです。
   ***************************************************************************
   */
  public void inputFreightCarrier()
  {
    // 入出庫実績ヘッダ:登録PVO取得
    OAViewObject resultsHdrPVO = getXxinvMovementResultsHdPVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)resultsHdrPVO.first();

    // ヘッダ.運送業者を入力可能に変更
    readOnlyRow.setAttribute("FreightCarrierReadOnly", Boolean.FALSE);
    
  } // inputFreightCarrier

  /***************************************************************************
   * 入出庫実績ヘッダ画面の項目内容のクリア処理を行うメソッドです。
   ***************************************************************************
   */
  public void clearValue()
  {
    // 移動実績情報VO取得
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow  row = (OARow)vo.first();
    String freightChargeClass = (String)row.getAttribute("FreightChargeClass");

    // 運賃区分がOFFになった場合
    if ("0".equals(freightChargeClass))
    {
    // mod start ver1.5
      // 運送業者(実績)内容をクリア
//      row.setAttribute("ActualCareerId", null);
//      row.setAttribute("ActualFreightCarrierCode", null);
//      row.setAttribute("PartyName2", null);
    // mod end ver1.5
      // 配送区分をクリア
      row.setAttribute("ShippingMethodCode", null);
      row.setAttribute("ShippingMethodName", null);
    }
  } // clearValue

  /***************************************************************************
   * 入出庫実績ヘッダ画面の登録・更新時のチェックを行います。
   * @param btn  - ボタン 1:次へボタン押下時 2:ヘッダ適用ボタン押下時
   * @throws OAException - OA例外
   ***************************************************************************
   */
// 2008-10-21 H.Itou Mod Start 統合テスト指摘353
//  public void checkHdr()
  public void checkHdr(String btn)
// 2008-10-21 H.Itou Mod End
// 2008-09-24 H.Itou Add Start
     throws OAException
// 2008-09-24 H.Itou Add End
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    
    // 移動実績情報VO取得
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow  row = (OARow)vo.first();
    String movNum            = (String)row.getAttribute("MovNum");        // 移動番号
    String movType           = (String)row.getAttribute("MovType");       // 移動タイプ
    String compActualFlg     = (String)row.getAttribute("CompActualFlg"); // 実績計上フラグ
// 2008-09-24 H.Itou Add Start 統合テスト指摘156 出庫元・入庫先同一チェック
    String shippedLocat      = (String)row.getAttribute("ShippedLocatCode"); // 出庫元保管場所
    String shipToLocat       = (String)row.getAttribute("ShipToLocatCode");  // 入庫先保管場所
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
    Date dbActualShipDate    = (Date)row.getAttribute("DbActualShipDate");    // 出庫日(実績)
    Date dbActualArrivalDate = (Date)row.getAttribute("DbActualArrivalDate"); // 着日(実績)
// 2008-10-21 H.Itou Add End
// 2008-12-01 H.Itou Add Start
    String freightChargeClass       = (String)row.getAttribute("FreightChargeClass");       // 運賃区分
    String actualFreightCarrierCode = (String)row.getAttribute("ActualFreightCarrierCode"); // 運送業者
// 2008-12-01 H.Itou Add End

    // 実績データ区分VO取得
    OAViewObject resultSearchVo = getXxinvMovResultsSearchVO1();
    // 1行目を取得
    OARow  resultSearchRow = (OARow)resultSearchVo.first(); 
    String actualFlg       = (String)resultSearchRow.getAttribute("ActualFlg"); // 実績データ区分
// 2008-09-24 H.Itou Add End
// 2008-12-01 H.Itou Add Start
    // 運賃区分がONの場合、運送業者NULLはエラー
    if ("1".equals(freightChargeClass)
     && XxcmnUtility.isBlankOrNull(actualFreightCarrierCode))
    {
      // エラーメッセージトークン取得
      throw new OAAttrValException(
        OAAttrValException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "ActualFreightCarrierCode",
        actualFreightCarrierCode,
        XxcmnConstants.APPL_XXINV,
        XxinvConstants.XXINV10180);
    }
// 2008-12-01 H.Itou Add End

    // 移動番号が設定済かつ移動タイプが「積送なし」かつ実績計上済の場合
    if ((!XxcmnUtility.isBlankOrNull(movNum))
     && (XxinvConstants.MOV_TYPE_2.equals(movType))
     && (XxinvConstants.COMP_ACTUAL_FLG_Y.equals(compActualFlg)))
    {
      // 更新チェック
      chkActualTypeOn(vo, row, exceptions);

      // 例外があった場合、例外メッセージを出力し、処理終了
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }

    // 移動番号が設定済かつ移動タイプが「積送あり」かつ実績計上済の場合
    } else if ((!XxcmnUtility.isBlankOrNull(movNum))
            && (XxinvConstants.MOV_TYPE_1.equals(movType))
            && (XxinvConstants.COMP_ACTUAL_FLG_Y.equals(compActualFlg)))
    {
      // 更新チェック
      chkActualTypeOff(vo, row, exceptions);

      // 例外があった場合、例外メッセージを出力し、処理終了
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }

    // 指示なし新規登録(移動番号が設定済)場合
    } else if ((!XxcmnUtility.isBlankOrNull(movNum))
            && (XxinvConstants.COMP_ACTUAL_FLG_N.equals(compActualFlg)))
    {
      // 更新チェック
      chkInstr(vo, row, XxinvConstants.INPUT_FLAG_1, exceptions);

      // 例外があった場合、例外メッセージを出力し、処理終了
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }

    // 指示なし新規登録(移動番号が未設定)場合
    } else
    {
      // 更新チェック
      chkInstr(vo, row, XxinvConstants.INPUT_FLAG_2, exceptions);

      // 例外があった場合、例外メッセージを出力し、処理終了
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }

// 2008-10-21 H.Itou Add Start 統合テスト指摘353
    // 以下のいづれかの場合、在庫クローズチェックを行う。
    // ・ヘッダ適用ボタン押下時
    // ・次へボタン押下時で、DBの出庫実績日・DBの入庫実績日どちらにも値がない場合 (指示登録済で、実績を初めて登録する場合)
    if ((btn.equals("2"))
     || (btn.equals("1")
      && XxcmnUtility.isBlankOrNull(dbActualShipDate) 
      && XxcmnUtility.isBlankOrNull(dbActualArrivalDate)))
    {
      // 在庫クローズチェック
      stockCloseCheck(vo, row, exceptions);

      // 例外があった場合、例外メッセージを出力し、処理終了
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
// 2008-10-21 H.Itou Add Start 統合テスト指摘353

// 2008-09-24 H.Itou Add Start 統合テスト指摘156 出庫元・入庫先同一チェック
    if (!XxcmnUtility.isBlankOrNull(shippedLocat)
     && !XxcmnUtility.isBlankOrNull(shipToLocat)
     &&  shippedLocat.equals(shipToLocat))
    {
      throw new OAException(XxcmnConstants.APPL_XXINV, XxinvConstants.XXINV10119);
    }
// 2008-09-24 H.Itou Add End
  } // checkHdr

  /***************************************************************************
   * 入出庫実績ヘッダ画面の
   * 移動番号が設定済(実績訂正)かつ移動タイプ「積送なし」時のチェックを行います。
   * @param vo         チェック対象VO
   * @param row        チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkActualTypeOn(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    // 情報取得
    Object actualShipDate    = row.getAttribute("ActualShipDate");    // 出庫日(実績)
    Object actualArrivalDate = row.getAttribute("ActualArrivalDate"); // 着日(実績)

    // 出庫日(実績)、着日(実績)が同日の場合
    if (XxcmnUtility.isEquals(actualShipDate, actualArrivalDate))
    {
// 2008-12-25 H.Itou Mod Start
//      // 出庫日(実績)の未来日チェック
//      chkFutureDate(vo, row, "1", exceptions);
      // 未来日チェック
      chkDivFutureDate(vo, row, exceptions);
// 2008-12-25 H.Itou Mod End

    // 出庫日(実績)、着日(実績)が同日でない場合はエラー
    } else
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
      tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualShipDate",
                            actualShipDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10034,
                            tokens));

    }
  } // chkActualTypeOn

  /***************************************************************************
   * 入出庫実績ヘッダ画面の
   * 移動番号が設定済(実績訂正)かつ移動タイプ「積送あり」時のチェックを行います。
   * @param vo         チェック対象VO
   * @param row        チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkActualTypeOff(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    // ステータスを取得
    String status = (String)row.getAttribute("Status");
    // 実績日を取得
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // 出庫日(実績)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // 着日(実績)

    // 出庫日(実績) > 着日(実績)の場合
    if (XxcmnUtility.chkCompareDate(1, actualShipDate, actualArrivalDate))
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
      tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualShipDate",
                            actualShipDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10055,
                            tokens));

    // 出庫日(実績) <= 着日(実績)の場合
    } else if (XxcmnUtility.chkCompareDate(2, actualArrivalDate, actualShipDate))
    {
      // 実績データ区分VO取得
      OAViewObject actualVo = getXxinvMovResultsSearchVO1();
      // 1行目を取得
      OARow  actualVoRow = (OARow)actualVo.first(); 
      String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

// 2008-12-25 H.Itou Mod Start
//      // 出庫実績メニューから起動した場合
//      if ("1".equals(actualFlg))
//      {
//        // ステータスが「入庫報告有」又は「入出庫報告有」の場合
//        if ((XxinvConstants.STATUS_05.equals(status))
//              || (XxinvConstants.STATUS_06.equals(status)))
//        {
//          // 出庫日(実績)、着日(実績)の未来日チェック
//          chkFutureDate(vo, row, "3", exceptions);
//        } else
//        {
//          // 出庫日(実績)の未来日チェック
//          chkFutureDate(vo, row, "1", exceptions);
//        }

//      // 入庫実績メニューから起動した場合
//      } else if ("2".equals(actualFlg))
//      {
//        // ステータスが「出庫報告有」又は「入出庫報告有」の場合
//        if ((XxinvConstants.STATUS_04.equals(status))
//              || (XxinvConstants.STATUS_06.equals(status)))
//        {
//          // 出庫日(実績)、着日(実績)の未来日チェック
//          chkFutureDate(vo, row, "3", exceptions);
//        } else
//        {
//          // 着日(実績)の未来日チェック
//          chkFutureDate(vo, row, "2", exceptions);
//        }
//      }
      // 未来日チェック
      chkDivFutureDate(vo, row, exceptions);
// 2008-12-25 H.Itou Mod End
    }
    
  } // chkActualTypeOff

  /***************************************************************************
   * 入出庫実績ヘッダ画面の指示有、指示無の新規登録時のチェックを行います。
   * @param vo         チェック対象VO
   * @param row        チェック対象行
   * @param exeType    指示あり:1、指示無し:2
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkInstr(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    int i = 0;
    // 実績日を取得
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // 出庫日(実績)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // 着日(実績)
// 2008-12-25 H.Itou Mod Start
    String movType = (String)row.getAttribute("MovType"); // 移動タイプ
// 2008-12-25 H.Itou Mod End
    // 未入力チェック
    String retCode = (String)chkUninput(vo, row, exeType, exceptions);

    // 未入力チェックが正常終了の場合
    if (XxcmnConstants.STRING_TRUE.equals(retCode))
    {
      // 出庫日(実績)、 着日(実績)が入力済の場合
      if (!XxcmnUtility.isBlankOrNull(actualShipDate)
       && !XxcmnUtility.isBlankOrNull(actualArrivalDate))
      {
// 2008-12-25 H.Itou Mod Start
//        // 出庫日(実績) > 着日(実績)の場合
//        if (XxcmnUtility.chkCompareDate(1, actualShipDate, actualArrivalDate))
        // 移動タイプが1:積送ありで出庫日(実績) > 着日(実績)の場合
        if ( XxinvConstants.MOV_TYPE_1.equals(movType)
          && XxcmnUtility.chkCompareDate(1, actualShipDate, actualArrivalDate))
// 2008-12-25 H.Itou Mod End
        {
          // エラーメッセージトークン取得
          MessageToken[] tokens = new MessageToken[2];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualShipDate",
                                actualShipDate,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10055,
                                tokens));
// 2008-12-25 H.Itou Add Start
        // 移動タイプが2:積送なしで出庫日(実績)、着日(実績)が同日でない場合
        } else if ( XxinvConstants.MOV_TYPE_2.equals(movType)
                && !XxcmnUtility.isEquals(actualShipDate, actualArrivalDate))
        {
          // エラーメッセージトークン取得
          MessageToken[] tokens = new MessageToken[2];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualShipDate",
                                actualShipDate,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10034,
                                tokens));
// 2008-12-25 H.Itou Add End
        }
      }
      // 出庫日(実績) <= 着日(実績)の場合
      if (i == 0)
      {
// 2008-12-25 H.Itou Mod Start
//        // 実績データ区分VO取得
//        OAViewObject actualVo = getXxinvMovResultsSearchVO1();
//        // 1行目を取得
//        OARow  actualVoRow = (OARow)actualVo.first();
//        String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");
//
//        // 出庫実績メニューから起動した場合
//        if ("1".equals(actualFlg))
//        {
//          // 出庫日(実績)の未来日チェック
//          chkFutureDate(vo, row, "1", exceptions);
//
//        // 入庫実績メニューから起動した場合
//        } else if ("2".equals(actualFlg))
//        {
//          // 着日(実績)の未来日チェック
//          chkFutureDate(vo, row, "2", exceptions);
//        }
        // 未来日チェック
        chkDivFutureDate(vo, row, exceptions);
// 2008-12-25 H.Itou Mod End

        // 保管倉庫の未入力チェック
        chkLocat(vo, row, exeType,exceptions);
      }
    }
  } // chkInstr

  /***************************************************************************
   * 入出庫実績ヘッダ画面の保管倉庫の未入力チェックを行います。
   * @param vo         チェック対象VO
   * @param row        チェック対象行
   * @param exeType    指示あり:1、指示無し:2
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkLocat(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    String shippedLocat         = (String)row.getAttribute("ShippedLocatCode");    // 出庫元保管場所
    String shipToLocat          = (String)row.getAttribute("ShipToLocatCode");     // 入庫先保管場所
    String freightChargeClass   = (String)row.getAttribute("FreightChargeClass");  // 運賃区分
    String weightCapacityClass  = (String)row.getAttribute("WeightCapacityClass"); // 重力容積区分
    Date actualShipDate         = (Date)row.getAttribute("ActualShipDate");        // 出庫日(実績)

    // mod start ver1.3
    // 指示あり新規登録の場合
    /*if (XxinvConstants.INPUT_FLAG_1.equals(exeType))
    {
      // 実績データ区分VO取得
      OAViewObject actualVo = getXxinvMovResultsSearchVO1();
      // 1行目を取得
      OARow  actualVoRow = (OARow)actualVo.first(); 
      String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

      // 出庫実績メニューから起動した場合
      if ("1".equals(actualFlg))
      {
        // 出庫元保管場所が未入力の場合
        if (XxcmnUtility.isBlankOrNull(shippedLocat))
        {
          // メッセージ取得
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShippedLocatCode",
                                shippedLocat,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10064,
                                null));
        }

      // 入庫実績メニューから起動した場合
      } else if ("2".equals(actualFlg))
      {
        // 入庫先保管場所が未入力の場合
        if (XxcmnUtility.isBlankOrNull(shipToLocat))
        {
          // メッセージ取得
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShipToLocatCode",
                                shipToLocat,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10064,
                                null));
        }
        
      }*/

    // 指示なし新規登録の場合
    //} else if (XxinvConstants.INPUT_FLAG_2.equals(exeType))
    if (XxinvConstants.INPUT_FLAG_2.equals(exeType))
    {
      // 出庫元保管場所が未入力の場合
      /*if (XxcmnUtility.isBlankOrNull(shippedLocat))
      {
        // メッセージ取得
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShippedLocatCode",
                              shippedLocat,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10064,
                              null));

      // 入庫先保管場所が未入力の場合
      } else if (XxcmnUtility.isBlankOrNull(shipToLocat))
      {
        // メッセージ取得
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShipToLocatCode",
                              shipToLocat,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10064,
                              null));
      }*/
      // 出庫元、入庫先どちらも入力済かつ運賃区分ONの場合
      //if ((exceptions.size() == 0) && ("1".equals(freightChargeClass)))
      if ("1".equals(freightChargeClass))
      // mod start ver1.3
      {
        // 最大配送区分を算出する
        HashMap paramsRet = XxinvUtility.getMaxShipMethod(
                              getOADBTransaction(),
                              "4", // 倉庫
                              shippedLocat,
                              "4", // 倉庫
                              shipToLocat,
                              weightCapacityClass,
                              null,
                              actualShipDate);

        // 最大配送区分が取得できなかった場合
        if (XxcmnUtility.isBlankOrNull(paramsRet.get("maxShipMethods"))) 
        {
          // エラーメッセージ出力
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_MSG, XxinvConstants.TOKEN_NAME_MAX_SHIP_METHOD);
          throw new OAAttrValException(
                      OAAttrValException.TYP_VIEW_OBJECT,
                      vo.getName(),
                      row.getKey(),
                      "ShipToLocatCode",
                      shipToLocat,
                      XxcmnConstants.APPL_XXINV,
                      XxinvConstants.XXINV10009,
                      tokens);
        } else 
        {
          // 配送区分にセット
          row.setAttribute("ActualShippingMethodCode", paramsRet.get("maxShipMethods"));
        }
        
      }
    }
  } // chkLocat

  /***************************************************************************
   * 入出庫実績必須項目の未入力チェックを行います。
   * @param vo         チェック対象VO
   * @param row        チェック対象行
   * @param exeType    指示あり:1、指示無し:2
   * @param exceptions エラーリスト
   * @return String    正常:TRUE、異常:FALSE
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String chkUninput(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    String retCode = XxcmnConstants.STRING_TRUE;
    // 実績日を取得
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // 出庫日(実績)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // 着日(実績)
    // add start ver1.3
    // 保管場所を取得
    String shippedLocat    = (String)row.getAttribute("ShippedLocatCode"); // 出庫元保管場所
    String shipToLocat     = (String)row.getAttribute("ShipToLocatCode");  // 入庫先保管場所
    // add end ver1.3
// 2009-06-18 H.Itou Add Start 本番障害#1314
    // 移動指示部署を取得
    String instructionPostCode = (String)row.getAttribute("InstructionPostCode"); // 移動指示部署
// 2009-06-18 H.Itou Add End
    
// 2009-06-18 H.Itou Add Start 本番障害#1314
    // 移動指示部署が未入力の場合
    if (XxcmnUtility.isBlankOrNull(instructionPostCode))
    {
      // メッセージ取得
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "InstructionPostCode",
                            instructionPostCode,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10128,
                            null));
      retCode = XxcmnConstants.STRING_FALSE;
    }
// 2009-06-18 H.Itou Add End
    // 指示あり新規登録の場合
    if (XxinvConstants.INPUT_FLAG_1.equals(exeType))
    {
      // 実績データ区分VO取得
      OAViewObject actualVo = getXxinvMovResultsSearchVO1();
      // 1行目を取得
      OARow  actualVoRow = (OARow)actualVo.first(); 
      String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

      // 出庫実績メニューから起動した場合
      if ("1".equals(actualFlg))
      {
        // add start ver1.3
        // 出庫元保管場所が未入力の場合
        if (XxcmnUtility.isBlankOrNull(shippedLocat))
        {
          // メッセージ取得
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShippedLocatCode",
                                shippedLocat,
                                XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                                XxinvConstants.XXINV10064,
                                XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                                null));
          retCode = XxcmnConstants.STRING_FALSE;
        }
        // add end ver1.3
        // 出庫日(実績)が未入力の場合
        if (XxcmnUtility.isBlankOrNull(actualShipDate))
        {
          // エラーメッセージトークン取得
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualShipDate",
                                actualShipDate,
                                XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                                XxinvConstants.XXINV10131,
                                XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                                tokens));
          retCode = XxcmnConstants.STRING_FALSE;
        }

      // 入庫実績メニューから起動した場合
      } else if ("2".equals(actualFlg))
      {
        // add start ver1.3
        // 入庫先保管場所が未入力の場合
        if (XxcmnUtility.isBlankOrNull(shipToLocat))
        {
          // メッセージ取得
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShipToLocatCode",
                                shipToLocat,
                                XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                                XxinvConstants.XXINV10064,
                                XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                                null));
          retCode = XxcmnConstants.STRING_FALSE;
        }
        // add end ver1.3
        // 着日(実績)が未入力の場合
        if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
        {
          // エラーメッセージトークン取得
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualArrivalDate",
                                actualArrivalDate,
                                XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                                XxinvConstants.XXINV10131,
                                XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                                tokens));
          retCode = XxcmnConstants.STRING_FALSE;
        }
      }
      
    // 指示なし新規登録の場合
    } else
    {
      // add start ver1.3
      // 出庫元保管場所が未入力の場合
      if (XxcmnUtility.isBlankOrNull(shippedLocat))
      {
        // メッセージ取得
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShippedLocatCode",
                              shippedLocat,
                              XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                              XxinvConstants.XXINV10064,
                              XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                              null));
        retCode = XxcmnConstants.STRING_FALSE;

      }
      // 入庫先保管場所が未入力の場合
      if (XxcmnUtility.isBlankOrNull(shipToLocat))
      {
        // メッセージ取得
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShipToLocatCode",
                              shipToLocat,
                              XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                              XxinvConstants.XXINV10064,
                              XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                              null));
        retCode = XxcmnConstants.STRING_FALSE;
      }
      // add end ver1.3
      // 出庫日(実績)が未入力の場合
      if (XxcmnUtility.isBlankOrNull(actualShipDate))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualShipDate",
                              actualShipDate,
                              XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                              XxinvConstants.XXINV10131,
                              XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                              tokens));
        retCode = XxcmnConstants.STRING_FALSE;

      // 着日(実績)が未入力の場合
      // mod start ver1.3
      //} else if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
      }
      if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
      // mod end ver1.3
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualArrivalDate",
                              actualArrivalDate,
                              XxcmnConstants.APPL_XXINV,
// 2009-06-18 H.Itou Mod Start
//                              XxinvConstants.XXINV10131,
                              XxinvConstants.XXINV10128,
// 2009-06-18 H.Itou Mod End
                              tokens));
        retCode = XxcmnConstants.STRING_FALSE;
      }
    }

    return retCode;
  } // chkUninput

// 2008-12-25 H.Itou Add Start
  /***************************************************************************
   * 入出庫実績ヘッダ画面の未来日チェックの分岐を行います。
   * @param vo        チェック対象VO
   * @param row       チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkDivFutureDate(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
  /* ------------------------------------------------------------------------------------
   * 2008-12-25 新規追加
   *  実績計上前かつ入庫報告有の場合、出庫実績画面で入庫日に未来日を入力できてしまうため
   *  どの場合でもステータスと起動メニューにより、チェック対象を分岐する。
   *  【出庫実績日のみチェック】
   *  【入庫実績日のみチェック】
   *  【出庫実績日・入庫実績日チェック】
   * ------------------------------------------------------------------------------------ */
    String status = (String)row.getAttribute("Status"); // ステータス

    OAViewObject actualVo = getXxinvMovResultsSearchVO1(); // 検索VO
    OARow  actualVoRow    = (OARow)actualVo.first(); 
    String actualFlg      = (String)actualVoRow.getAttribute("ActualFlg"); // 起動メニューフラグ
    
    // 出庫実績メニューから起動した場合
    if ("1".equals(actualFlg))
    {
      // ステータスが「入庫報告有」又は「入出庫報告有」の場合
      if ((XxinvConstants.STATUS_05.equals(status))
       || (XxinvConstants.STATUS_06.equals(status)))
      {
        // 出庫日(実績)、着日(実績)の未来日チェック
        chkFutureDate(vo, row, "3", exceptions);
      } else
      {
        // 出庫日(実績)の未来日チェック
        chkFutureDate(vo, row, "1", exceptions);
      }

    // 入庫実績メニューから起動した場合
    } else if ("2".equals(actualFlg))
    {
      // ステータスが「出庫報告有」又は「入出庫報告有」の場合
      if ((XxinvConstants.STATUS_04.equals(status))
       || (XxinvConstants.STATUS_06.equals(status)))
      {
        // 出庫日(実績)、着日(実績)の未来日チェック
        chkFutureDate(vo, row, "3", exceptions);
      } else
      {
        // 着日(実績)の未来日チェック
        chkFutureDate(vo, row, "2", exceptions);
      }
    }
  } // chkDivFutureDate
// 2008-12-25 H.Itou Add End

  /***************************************************************************
   * 入出庫実績ヘッダ画面の未来日のチェックを行います。
   * @param vo        チェック対象VO
   * @param row       チェック対象行
   * @param exeType   出庫日(実績)をチェック:1、着日(実績)をチェック:2、両日チェック:3
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkFutureDate(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    // SYSDATEを取得
    Date sysdate = XxinvUtility.getSysdate(getOADBTransaction());

    // 実績日を取得
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // 出庫日(実績)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // 着日(実績)

    // 未来日エラーカウント
    int errCount = 0;

    // 出庫日(実績)をチェックする場合
    if ("1".equals(exeType))
    {

      // 出庫日(実績)が未来日の場合
      if (XxcmnUtility.chkCompareDate(1, actualShipDate, sysdate))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualShipDate",
                              actualShipDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10066,
                              tokens));
        // エラーをカウント
        errCount = errCount + 1;

      }

    // 着日(実績)をチェックする場合
    } else if ("2".equals(exeType))
    {
      // 着日(実績)が未来日の場合
      if (XxcmnUtility.chkCompareDate(1, actualArrivalDate, sysdate))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualArrivalDate",
                              actualArrivalDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10067,
                              tokens));
        // エラーをカウント
        errCount = errCount + 1;
      }

    // 出庫日(実績)、着日(実績)の両日をチェックする場合
    } else if ("3".equals(exeType))
    {
      // 出庫日(実績)が未来日の場合
      if (XxcmnUtility.chkCompareDate(1, actualShipDate, sysdate))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualShipDate",
                              actualShipDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10066,
                              tokens));
        // エラーをカウント
        errCount = errCount + 1;

      // 着日(実績)が未来日の場合
      } else if (XxcmnUtility.chkCompareDate(1, actualArrivalDate, sysdate))
      {
        // エラーメッセージトークン取得
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualArrivalDate",
                              actualArrivalDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10067,
                              tokens));
        // エラーをカウント
        errCount = errCount + 1;
      }
    }
// 2008-10-21 H.Itou Del Start 統合テスト指摘353
//    // 未来日でない場合
//    if (errCount == 0)
//    {
//      // OPM在庫クローズチェック
//      stockCloseCheck(vo, row, exceptions);
//    }
// 2008-10-21 H.Itou Del End
  } // chkFutureDate

  /***************************************************************************
   * 入出庫実績ヘッダ画面のOPM在庫クローズチェックを行うメソッドです。
   * @param vo        チェック対象VO
   * @param row       チェック対象行
   * @param exceptions エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void stockCloseCheck(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    //実績日を取得
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // 出庫日(実績)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // 着日(実績)

    // 在庫クローズチェック:出庫日(実績)
    if (XxinvUtility.chkStockClose(
          getOADBTransaction(), // トランザクション
          actualShipDate)       // 出庫日(実績)
        )
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[1];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualShipDate",
                            actualShipDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10120,
                            tokens));

    }
    // 在庫クローズチェック:着日(実績)
    if (XxinvUtility.chkStockClose(
          getOADBTransaction(), // トランザクション
          actualArrivalDate)    // 着日(実績)
        )
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[1];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualArrivalDate",
                            actualArrivalDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10120,
                            tokens));

    }
  } // stockCloseCheck

  /****************************************************************************
   * 入出庫実績ヘッダ画面の稼動日チェックを行うメソッドです。
   * @return String リターンコード(正常(更新無)：TRUE、
   *           エラー(出庫実績メニュー起動)：1、エラー(入庫実績メニュー起動)：2)
   * @throws OAException - OA例外
   ****************************************************************************
   */
  public String oprtnDayCheck() throws OAException
  {
    String retCode = XxcmnConstants.STRING_TRUE;
    // INパラメータ
    Date   originalDate = null; // 基準日
    String shipWhseCode = null; // 保管倉庫コード
    // 戻り値
    Date   oprtnDay;
    // 移動実績情報VO取得
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow  row      = (OARow)vo.first();

    // 実績データ区分VO取得
    OAViewObject actualVo = getXxinvMovResultsSearchVO1();
    // 1行目を取得
    OARow  actualVoRow = (OARow)actualVo.first(); 
    String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

    // 出庫実績メニューから起動した場合
    if ("1".equals(actualFlg))
    {
      // パラメータ設定
    originalDate = (Date)row.getAttribute("ActualShipDate");     // 出庫日(実績)
    shipWhseCode = (String)row.getAttribute("ShippedLocatCode"); // 出庫元
    retCode = actualFlg;

    // 入庫実績メニューから起動した場合
    } else if ("2".equals(actualFlg))
    {
      // パラメータ設定
      originalDate = (Date)row.getAttribute("ActualArrivalDate");  // 着日(実績)
      shipWhseCode = (String)row.getAttribute("ShipToLocatCode");  // 入庫先
      retCode = actualFlg;
    }
    // 稼動日チェック
    oprtnDay = XxinvUtility.getOprtnDay(
                 getOADBTransaction(),
                 originalDate,
                 shipWhseCode,
                 null,
                 0);

    if (XxcmnUtility.isBlankOrNull(oprtnDay))
    {
      return retCode;
    }
    return XxcmnConstants.STRING_TRUE;
  } // oprtnDayCheck

  /***************************************************************************
   * コンカレント：移動入出庫実績登録処理です。
   * @return HashMap - リターンコード
   ***************************************************************************
   */
  public HashMap doMovActualMake()
  {
    // 移動番号を取得
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    OARow row       = (OARow)vo.first();
    String movNum   = (String)row.getAttribute("MovNum");
// 2008-12-25 H.Itou Add Start
// 2009-12-28 H.Itou Del Start 本稼動障害#695
//  	Number movHeaderId = (Number)row.getAttribute("MovHdrId");
//    // 全移動明細出庫実績数量登録済チェック (true:登録済  false:未登録あり)
//    boolean shippedResultFlag = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1");
//    // 全移動明細入庫実績数量登録済チェック (true:登録済  false:未登録あり)
//    boolean shipToResultFlag  = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2");
//
//    // 移動明細の出庫実績数量・入庫実績数量が共にすべて登録済の場合
//    if (shippedResultFlag && shipToResultFlag)
//    {
//// 2008-12-25 H.Itou Add End
//      // INパラメータ用HashMap生成
//      HashMap inParams = new HashMap();
//      inParams.put("MovNum", movNum);
//
//      // 移動入出庫実績登録処理実行
//      return XxinvUtility.doMovShipActualMake(
//                            getOADBTransaction(), // トランザクション
//                            inParams              // パラメータ
//                            );
//// 2008-12-25 H.Itou Add Start
//    // 移動明細の出庫実績数量・入庫実績数量が登録されていない場合、コンカレントを起動しない。
//    } else
//    {
// 2009-12-28 H.Itou Del End
      HashMap retParams = new HashMap();
      retParams.put("retFlag", null);
      return retParams;
// 2009-12-28 H.Itou Del Start 本稼動障害#695
//    }
// 2009-12-28 H.Itou Del End
// 2008-12-25 H.Itou Add End
  } // doMovActualMake

  /***************************************************************************
   * パレット枚数(出/入)のチェックメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chckPallet() throws OAException
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);

    OAViewObject hdrVo = getXxinvMovementResultsHdVO1();
    OARow hdrRow       = (OARow)hdrVo.first();
    // パレット回収枚数が更新された場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("CollectedPalletQty"),
          hdrRow.getAttribute("DbCollectedPalletQty")))
    {
      Object collectedPalletQty = hdrRow.getAttribute("CollectedPalletQty");
      // パレット回収枚数に値が入力されている場合
      if (!XxcmnUtility.isBlankOrNull(collectedPalletQty))
      {
        // 数値(999)でない場合はエラー
        if (!XxcmnUtility.chkNumeric(collectedPalletQty, 3, 0)) 
        {
          exceptions.add(
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  hdrVo.getName(),
                  hdrRow.getKey(),
                  "CollectedPalletQty",
                  collectedPalletQty,
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10160));
        } else 
        {
          // マイナス値はエラー
          if (!XxcmnUtility.chkCompareNumeric(2, collectedPalletQty, "0"))
          {
            exceptions.add(
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,
                    hdrVo.getName(),
                    hdrRow.getKey(),
                    "CollectedPalletQty",
                    collectedPalletQty,
                    XxcmnConstants.APPL_XXINV,
                    XxinvConstants.XXINV10030));
          }
        }
      }
    }
    // パレット枚数(出)が更新された場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("OutPalletQty"),
          hdrRow.getAttribute("DbOutPalletQty")))
    {
      Object outPalletQty = hdrRow.getAttribute("OutPalletQty");
      // パレット枚数(出)に値が入力されている場合
      if (!XxcmnUtility.isBlankOrNull(outPalletQty))
      {
        // 数値(999)でない場合はエラー
        if (!XxcmnUtility.chkNumeric(outPalletQty, 3, 0)) 
        {
          exceptions.add(
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  hdrVo.getName(),
                  hdrRow.getKey(),
                  "OutPalletQty",
                  outPalletQty,
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10160));

        } else 
        {
          // マイナス値はエラー
          if (!XxcmnUtility.chkCompareNumeric(2, outPalletQty, "0"))
          {
            exceptions.add(
              new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,
                hdrVo.getName(),
                hdrRow.getKey(),
                "OutPalletQty",
                outPalletQty,
                XxcmnConstants.APPL_XXINV,
                XxinvConstants.XXINV10030));
          }
        }
      }
      
    }
    // パレット枚数(入)が更新された場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("InPalletQty"),
          hdrRow.getAttribute("DbInPalletQty")))
    {
      Object inPalletQty = hdrRow.getAttribute("InPalletQty");
      // パレット枚数(入)に値が入力されている場合
      if (!XxcmnUtility.isBlankOrNull(inPalletQty))
      {
        // 数値(999)でない場合はエラー
        if (!XxcmnUtility.chkNumeric(inPalletQty, 3, 0)) 
        {
          exceptions.add(
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  hdrVo.getName(),
                  hdrRow.getKey(),
                  "InPalletQty",
                  inPalletQty,
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10160));

        } else 
        {
          // マイナス値はエラー
          if (!XxcmnUtility.chkCompareNumeric(2, inPalletQty, "0"))
          {
            exceptions.add(
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,
                    hdrVo.getName(),
                    hdrRow.getKey(),
                    "InPalletQty",
                    inPalletQty,
                    XxcmnConstants.APPL_XXINV,
                    XxinvConstants.XXINV10030));
          }
        }
      }
    }
    // エラーがある場合、インラインメッセージ出力
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chckPallet

  /***************************************************************************
   * 入出庫実績ヘッダの更新処理を行うメソッドです。
   * @return String リターンコード(正常(更新有)：MovHdrId、正常(更新無)：TRUE、エラー：FALSE)
   ***************************************************************************
   */
  public String UpdateHdr()
  {
    //
    String retCode  = XxcmnConstants.STRING_TRUE;
    String updFlag  = XxcmnConstants.STRING_N;

    OAViewObject makeHdrVO = getXxinvMovementResultsHdVO1();
    OARow makeHdrVORow = (OARow)makeHdrVO.first();
    Number movHdrId = (Number)makeHdrVORow.getAttribute("MovHdrId");
// 2009-02-09 H.Itou Add Start 本番障害#1143対応
    String movNum   = (String)makeHdrVORow.getAttribute("MovNum");
// 2009-02-09 H.Itou Add End

    // *************************** //
    // *   ヘッダー更新処理      * //
    // *************************** //
    if ((!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
                                makeHdrVORow.getAttribute("DbActualShipDate")))    // 出庫日(実績)：出庫日(実績)(DB)
     || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                                makeHdrVORow.getAttribute("DbActualArrivalDate"))) // 着日(実績)：着日(実績)(DB)
     || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                                makeHdrVORow.getAttribute("DbOutPalletQty")))      // パレット枚数(出)：パレット枚数(出)(DB)
     || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                                makeHdrVORow.getAttribute("DbInPalletQty"))))      // パレット枚数(入)：パレット枚数(入)(DB)
    {
      // 実績計上済フラグがYの場合
      if (XxcmnConstants.STRING_Y.equals(makeHdrVORow.getAttribute("CompActualFlg")))
      {
        makeHdrVORow.setAttribute("CorrectActualFlg", XxcmnConstants.STRING_Y);
      }
      // 移動依頼/指示ヘッダ(アドオン)更新処理
      retCode = headerUpdate(makeHdrVORow);

      // ヘッダ更新処理でエラーが発生した場合、処理を中断
      if (XxcmnConstants.STRING_FALSE.equals(retCode))
      {
        return retCode;
      }
      // 出庫日(実績)が更新された場合
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
            makeHdrVORow.getAttribute("DbActualShipDate")))
      {
        // 出庫日(実績)(DB)に更新した値をセット
//      makeHdrVORow.setAttribute("DbActualShipDate", makeHdrVORow.getAttribute("ActualShipDate"));
        // ロット詳細確認処理
        if (XxinvUtility.chkLotDetails(
                           getOADBTransaction(),         // トランザクション
                           movHdrId,                     // 移動ヘッダID
                           XxinvConstants.RECORD_TYPE_20 // レコードタイプ
                           )
           )
        {
          // 移動ロット詳細実行日の更新処理
          retCode = lotUpdate(makeHdrVORow, XxinvConstants.RECORD_TYPE_20);
        }

      }
      // 着日(実績)が更新された場合
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                                 makeHdrVORow.getAttribute("DbActualArrivalDate")))
      {
        // 着日(実績)(DB)に更新した値をセット
//      makeHdrVORow.setAttribute("DbActualArrivalDate", makeHdrVORow.getAttribute("ActualArrivalDate"));
        // ロット詳細確認処理
        if (XxinvUtility.chkLotDetails(
                           getOADBTransaction(),         // トランザクション
                           movHdrId,                     // 移動ヘッダID
                           XxinvConstants.RECORD_TYPE_30 // レコードタイプ
                           )
          )
        {
          // 移動ロット詳細実行日の更新処理
          retCode = lotUpdate(makeHdrVORow, XxinvConstants.RECORD_TYPE_30);
        }
      }
      // パレット枚数(出)が更新された場合
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                                 makeHdrVORow.getAttribute("DbOutPalletQty")))
      {
        // パレット枚数(出)(DB)に更新した値をセット
        makeHdrVORow.setAttribute("DbOutPalletQty", makeHdrVORow.getAttribute("OutPalletQty"));
      }
      // パレット枚数(入)が更新された場合
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                                 makeHdrVORow.getAttribute("DbInPalletQty")))
      {
        // パレット枚数(入)(DB)に更新した値をセット
        makeHdrVORow.setAttribute("DbInPalletQty", makeHdrVORow.getAttribute("InPalletQty"));
      }
      
// 2009-02-09 H.Itou Add Start 本番障害#1143対応
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
// 2009-02-09 H.Itou Add End
      updFlag = XxcmnConstants.STRING_Y;
    }

    // 更新処理が正常に終了した場合、再検索用に移動ヘッダIDを戻す
    if (XxcmnConstants.STRING_Y.equals(updFlag))
    {
      retCode = XxcmnUtility.stringValue(movHdrId);

    // 更新無し終了した場合、STRING_TRUEを戻す
    } else
    {
      retCode = XxcmnConstants.STRING_TRUE;
    }
    return retCode;
  } // UpdateHdr

  /***************************************************************************
   * 入出庫実績ヘッダ画面の移動依頼/指示ヘッダUPDATE処理を行うメソッドです。
   * @param makeHdrVORow 更新対象行
   * @return String 正常：TRUE、エラー：FALSE
   ***************************************************************************
   */
  public String headerUpdate(OARow makeHdrVORow)
  {
    // 移動依頼/指示ヘッダVOデータ取得
    HashMap params = new HashMap();

    // 移動ヘッダID
    params.put("MovHdrId",          makeHdrVORow.getAttribute("MovHdrId"));

    // 出庫日(実績)
    params.put("ActualShipDate",    makeHdrVORow.getAttribute("ActualShipDate"));

    // 着日(実績)
    params.put("ActualArrivalDate", makeHdrVORow.getAttribute("ActualArrivalDate"));

    // パレット枚数(出)
    params.put("OutPalletQty",      makeHdrVORow.getAttribute("OutPalletQty"));

    // パレット枚数(入)
    params.put("InPalletQty",       makeHdrVORow.getAttribute("InPalletQty"));

    // 運送業者_ID_実績
    if (XxcmnUtility.isBlankOrNull(makeHdrVORow.getAttribute("ActualCareerId")))
    {
      // 運送業者IDをセット
      params.put("ActualCareerId", makeHdrVORow.getAttribute("CareerId"));
    } else
    {
      // 運送業者_ID_実績をセット
      params.put("ActualCareerId", makeHdrVORow.getAttribute("ActualCareerId"));
    }

    // 運送業者_実績
    if (XxcmnUtility.isBlankOrNull(makeHdrVORow.getAttribute("ActualFreightCarrierCode")))
    {
      // 運送業者をセット
      params.put("ActualFreightCarrierCode", makeHdrVORow.getAttribute("FreightCarrierCode"));
    } else
    {
      // 運送業者_実績をセット
      params.put("ActualFreightCarrierCode", makeHdrVORow.getAttribute("ActualFreightCarrierCode"));
    }

    // 配送区分_実績
    if (XxcmnUtility.isBlankOrNull(makeHdrVORow.getAttribute("ActualShippingMethodCode")))
    {
      // 配送区分をセット
      params.put("ActualShippingMethodCode", makeHdrVORow.getAttribute("ShippingMethodCode"));
    } else
    {
      // 配送区分_実績をセット
      params.put("ActualShippingMethodCode", makeHdrVORow.getAttribute("ActualShippingMethodCode"));
    }

    // 着荷時間FROM
    params.put("ArrivalTimeFrom",  makeHdrVORow.getAttribute("ArrivalTimeFrom"));

    // 着荷時間TO
    params.put("ArrivalTimeTo",    makeHdrVORow.getAttribute("ArrivalTimeTo"));

    // 実績訂正フラグ
    params.put("CorrectActualFlg", makeHdrVORow.getAttribute("CorrectActualFlg"));

    // 最終更新日
    params.put("LastUpdateDate",   makeHdrVORow.getAttribute("LastUpdateDate"));

    // ロック・排他処理
    chkLockAndExclusive(params);

    // 移動依頼/指示ヘッダー更新：実行
    String retCode =  XxinvUtility.updateMovReqInsrtHdr(
                        getOADBTransaction(), // トランザクション
                        params                // パラメータ
                        );

    // 更新処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    }
    
    return XxcmnConstants.STRING_TRUE;
  } // headerUpdate

  /***************************************************************************
   * 入出庫実績ヘッダ画面の移動依頼/指示ヘッダロック・排他処理を行うメソッドです。
   * @param params - 検索用パラメータ
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void chkLockAndExclusive(
    HashMap params
  ) throws OAException
  {
    // ロックを取得します
    Number headerId = (Number)params.get("MovHdrId");

    if (!XxinvUtility.getMovReqInstrHdrLock(getOADBTransaction(), headerId))
    {
      XxinvUtility.rollBack(getOADBTransaction());
      // ロックエラーメッセージ
      throw new OAException(XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10159);
    }

    // 排他チェックをします
    String lastUpdateDate = (String)params.get("LastUpdateDate");
    if (!XxinvUtility.chkExclusiveMovReqInstrHdr(getOADBTransaction(), 
                        headerId,
                        lastUpdateDate))
    {
// 2008-10-21 H.Itou Add Start
      // 自分自身のコンカレント起動により更新された場合は排他エラーとしない
      if (!XxinvUtility.isMovHdrUpdForOwnConc(
             getOADBTransaction(),
             headerId,
             XxinvConstants.CONC_NAME_XXINV570001C))
      {
// 2008-10-21 H.Itou Add End
        // ロールバック
        XxinvUtility.rollBack(getOADBTransaction());
        
        // 排他エラーメッセージ出力
        throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10147);
// 2008-10-21 H.Itou Add Start
      }
// 2008-07-10 H.Itou Mod END
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * 移動ロット詳細(アドオン)実績日のUPDATE処理を行うメソッドです。
   * @param makeHdrVORow 更新対象行
   * @param recordType 　レコードタイプ
   * @return String 正常：TRUE、エラー：FALSE
   ***************************************************************************
   */
  public String lotUpdate(
    OARow makeHdrVORow,
    String recordType)
  {
    // 移動依頼/指示ヘッダVOデータ取得
    HashMap params = new HashMap();

    // 移動ヘッダID
    params.put("MovHdrId",          makeHdrVORow.getAttribute("MovHdrId"));

    // レコードタイプ
    params.put("RecordType",        recordType);
    
    // 出庫日(実績)
    params.put("ActualShipDate",    makeHdrVORow.getAttribute("ActualShipDate"));

    // 着日(実績)
    params.put("ActualArrivalDate", makeHdrVORow.getAttribute("ActualArrivalDate"));


    // 移動ロット詳細(アドオン)更新：実行
    String retCode =  XxinvUtility.updateMovLotDetails(
                        getOADBTransaction(), // トランザクション
                        params                // パラメータ
                        );

    // 更新処理が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    }
    
    return XxcmnConstants.STRING_TRUE;
  } // lotUpdate

  /***************************************************************************
   * 入出庫実績明細画面の初期化処理を行うメソッドです。
   * @param searchParams - パラメータHashMap
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void initializeLine(
    HashMap searchParams
  ) throws OAException
  {
    // パラメータ取得
    String peopleCode  = (String)searchParams.get(XxinvConstants.URL_PARAM_PEOPLE_CODE);
    String actualFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_ACTUAL_FLAG);
    String productFlag = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);
    String updateFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_UPDATE_FLAG);

    // ************************************* //
    // * 入出庫実績ヘッダ:登録VO 空行取得  * //
    // ************************************* //
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1行もない場合、空行作成
    if (!movementResultsHdVo.isPreparedForExecution())
    {
      movementResultsHdVo.setWhereClauseParam(0,null);
      movementResultsHdVo.executeQuery();
      movementResultsHdVo.insertRow(movementResultsHdVo.createRow());
      // 1行目を取得
      OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
      // キーに値をセット
      movementResultsHdRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsHdRow.setAttribute("MovHdrId", new Number(-1));
    }
    
    // ************************************* //
    // * 入出庫実績明細:登録VO 空行取得    * //
    // ************************************* //
    OAViewObject lnVo = getXxinvMovementResultsLnVO1();
    lnVo.setWhereClauseParam(0, null);
    lnVo.setWhereClauseParam(1, null);
    lnVo.setWhereClauseParam(2, null);
    lnVo.setWhereClauseParam(3, null);
// 2008/08/21 v1.6 Y.Yamamoto Mod Start
//    lnVo.setWhereClauseParam(4, null);
//    lnVo.setWhereClauseParam(5, null);
    lnVo.setWhereClauseParam(4, null);
// 2008/08/21 v1.6 Y.Yamamoto Mod End
    lnVo.executeQuery();

    addRowLine();

    // ************************************* //
    // *    入出庫実績:検索VO 空行取得     * //
    // ************************************* //
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1行もない場合、空行作成
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1行目を取得
      OARow resultsSearchVoRow = (OARow)resultsSearchVo.first();
      // キーに値をセット
      resultsSearchVoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchVoRow.setAttribute("RowKey",     new Number(1));
      resultsSearchVoRow.setAttribute("PeopleCode", peopleCode);
      resultsSearchVoRow.setAttribute("ActualFlg",  actualFlag);
      resultsSearchVoRow.setAttribute("ProductFlg", productFlag);
      resultsSearchVoRow.setAttribute("UpdateFlag", updateFlag);
      resultsSearchVoRow.setAttribute("ExeFlag",    null);
    } else
    {
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      resultsSearchRow.setAttribute("ExeFlag", "1");
    }
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
    // ************************************* //
    // * 入出庫実績明細:PVO 空行取得       * //
    // ************************************* //
    OAViewObject movementResultsLnPvo = getXxinvMovementResultsLnPVO1();
    // 1行もない場合、空行作成
    if (!movementResultsLnPvo.isPreparedForExecution())
    {
      movementResultsLnPvo.setMaxFetchSize(0);
      movementResultsLnPvo.insertRow(movementResultsLnPvo.createRow());
      // 1行目を取得
      OARow movementResultsLnPvoRow = (OARow)movementResultsLnPvo.first();
      // キーに値をセット
      movementResultsLnPvoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsLnPvoRow.setAttribute("RowKey", new Number(1));
    }
// 2008-10-21 H.Itou Add End
  } // initializeLine

  /***************************************************************************
   * 入出庫実績明細画面の新規行挿入処理を行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void addRowLine() throws OAException
  {
    OARow maxRow = null;
    Number maxLineNumber = new Number(0);

    // 入出庫実績明細:登録VO取得
    OAViewObject movementResultsLnVo = getXxinvMovementResultsLnVO1();

    // 行挿入
    OARow row = (OARow)movementResultsLnVo.createRow();

    row.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
    row.setAttribute("ShipToLotSwitcher",  "ShipToLotDetailsDisable");

    // 処理フラグ1:登録をセット
    row.setAttribute("ProcessFlag",         XxinvConstants.PROCESS_FLAG_I); // 処理フラグ 1:登録
// 2009-02-26 v1.12 D.Nihei Add Start 本番障害#855対応 削除処理追加
    row.setAttribute("DeleteSwitcher",      "DeleteDisable"); // 削除アイコン：押下不可
// 2009-02-26 v1.12 D.Nihei Add End
    movementResultsLnVo.last();
    movementResultsLnVo.next();
    movementResultsLnVo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);

    movementResultsLnVo.first();
    while (movementResultsLnVo.getCurrentRow() != null)
    {
      OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

      movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
      movementResultsLnRow.setAttribute("ShipToLotSwitcher",  "ShipToLotDetailsDisable");

      movementResultsLnVo.next();
    }

  } // addRowLine

  /***************************************************************************
   * 入出庫実績明細画面の検索処理を行うメソッドです。
   * @param searchParams - パラメータHashMap
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearchLine(
    HashMap searchParams
  ) throws OAException
  {
    // パラメータ取得
    String searchHdrId = (String)searchParams.get(XxinvConstants.URL_PARAM_SEARCH_MOV_ID);
    String productFlg  = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);
// 2009-03-11 H.Itou Add Start 本番障害#885
    String peopleCode  = (String)searchParams.get(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // 従業員区分
// 2009-03-11 H.Itou Add End

    // 入出庫実績明細:登録VO取得
    XxinvMovementResultsLnVOImpl movementResultsLnVo = getXxinvMovementResultsLnVO1();
    // 検索
    movementResultsLnVo.initQuery(
      searchHdrId,
      productFlg);
    // 1行めを取得
    movementResultsLnVo.first();
    // 入出庫実績ヘッダVO取得
    OAViewObject makeHdrVO = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow makeHdrVORow = (OARow)makeHdrVO.first();

    // データを取得できなかった場合
    if (movementResultsLnVo.getRowCount() == 0)
    {
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
      // *********************** //
      // *  入力制御           * //
      // *********************** //
      readOnlyChangedLine("1"); // 無効
// 2008-10-21 H.Itou Add End
      // *********************** //
      // *  VO初期化処理       * //
      // *********************** //
      OAViewObject vo = getXxinvMovementResultsLnVO1();
      vo.setWhereClauseParam(0, null);
      vo.setWhereClauseParam(1, null);
      vo.setWhereClauseParam(2, null);
      vo.setWhereClauseParam(3, null);
// 2008/08/21 v1.6 Y.Yamamoto Mod Start
//      vo.setWhereClauseParam(4, null);
//      vo.setWhereClauseParam(5, null);
      vo.setWhereClauseParam(4, null);
// 2008/08/21 v1.6 Y.Yamamoto Mod End
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      // 1行目を取得
      OARow row = (OARow)vo.first();
      // キーに値をセット
      row.setNewRowState(Row.STATUS_INITIALIZED);
      row.setAttribute("MovHdrId", new Number(-1));

      // ************************ //
      // * エラーメッセージ出力 *
      // ************************ //
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);

    // データを取得できた場合
    } else
    {
      OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
      
      // 1行目を取得
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      String actualFlg  = (String)resultsSearchRow.getAttribute("ActualFlg");

      // ヘッダ変更がなかった場合
      if ((XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
                                 makeHdrVORow.getAttribute("DbActualShipDate")))     // 出庫日(実績)：出庫日(実績)(DB)
       && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                                 makeHdrVORow.getAttribute("DbActualArrivalDate")))  // 着日(実績)：着日(実績)(DB)
       && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                                 makeHdrVORow.getAttribute("DbOutPalletQty")))       // パレット枚数(出)：パレット枚数(出)(DB)
       && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                                 makeHdrVORow.getAttribute("DbInPalletQty"))))       // パレット枚数(入)：パレット枚数(入)(DB)
      {
        resultsSearchRow.setAttribute("ExeFlag", "1");
// 2008-06-26 H.Ito Mod Start
      // ヘッダに変更があった場合、出庫実績ロット画面、入庫実績ロット画面遷移不可。
      } else
      {
        resultsSearchRow.setAttribute("ExeFlag", null);
      }
// 2008-06-26 H.Ito Mod End
      String exeFlg     = (String)resultsSearchRow.getAttribute("ExeFlag");

      // キーに値をセット
      resultsSearchRow.setAttribute("HdrId", searchHdrId);

      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();
        // 処理フラグ2:更新をセット
        movementResultsLnRow.setAttribute("ProcessFlag",      XxinvConstants.PROCESS_FLAG_U);
        // 品目の入力項目制御
        movementResultsLnRow.setAttribute("ItemCodeReadOnly", Boolean.TRUE);
// 2009-03-11 H.Itou Add Start 本番障害#885
        // 外部ユーザの場合
        if (XxinvConstants.PEOPLE_CODE_O.equals(peopleCode))
        {
          movementResultsLnRow.setAttribute("DeleteSwitcher",      "DeleteDisable"); // 削除アイコン：押下不可   
        }
// 2009-03-11 H.Itou Add End
        
        // 実績データ区分が:1(出庫実績)の場合
        if ("1".equals(actualFlg))
        {
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
          }
          movementResultsLnRow.setAttribute("ShipToLotSwitcher",    "ShipToLotDetailsDisable");

        // 実績データ区分が:2(入庫実績)の場合
        } else if ("2".equals(actualFlg))
        {
          movementResultsLnRow.setAttribute("ShippedLotSwitcher",  "ShippedLotDetailsDisable");
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");
          }
        }

        movementResultsLnVo.next();
      }
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
      readOnlyChangedLine("0"); // 有効
// 2008-10-21 H.Itou Add End
    }
  } // doSearchLine

// 2008-10-21 H.Itou Add Start 統合テスト指摘353
  /***************************************************************************
   * 入出庫実績明細画面の入力制御を行うメソッドです。
   * @param flag 処理フラグ
   ***************************************************************************
   */
  public void readOnlyChangedLine(String flag)
  {
    // 入出庫実績明細:PVO取得
    OAViewObject resultsLinePVO = getXxinvMovementResultsLnPVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)resultsLinePVO.first();
    
    // 初期化
    readOnlyRow.setAttribute("AddRowRendered", Boolean.TRUE);  // 行挿入：非表示
    readOnlyRow.setAttribute("GoDisabled",     Boolean.FALSE); // 適用：無効

    // 有効の場合
    if (flag.equals("0"))
    {
      // 移動実績情報ヘッダVO取得
      OAViewObject hdrVo = getXxinvMovementResultsHdVO1();
      // 1行目を取得
      OARow  hdrRow      = (OARow)hdrVo.first();

      String compActualFlg     = (String)hdrRow.getAttribute("CompActualFlg");
      Date   actualShipDate    = (Date)hdrRow.getAttribute("ActualShipDate");    // 出庫実績日
      Date   actualArrivalDate = (Date)hdrRow.getAttribute("ActualArrivalDate"); // 入庫実績日

      // 実績計上済で出庫実績日か入庫実績日がクローズしている場合
      if  (XxcmnConstants.STRING_Y.equals(compActualFlg)
        && XxinvUtility.chkStockClose(getOADBTransaction(), actualShipDate))
      {
        // 参照のみ。
        readOnlyRow.setAttribute("AddRowRendered", Boolean.FALSE); // 行挿入：非表示
        readOnlyRow.setAttribute("GoDisabled",     Boolean.TRUE);  // 適用：無効
      }

    // 無効の場合
    } else
    {
      readOnlyRow.setAttribute("AddRowRendered", Boolean.FALSE); // 行挿入：非表示
      readOnlyRow.setAttribute("GoDisabled",     Boolean.TRUE);  // 適用：無効
    }
  } // readOnlyChangedLine
// 2008-10-21 H.Itou Add End

  /***************************************************************************
   * 入出庫実績明細画面の登録・更新時のチェックを行います。
   ***************************************************************************
   */
  public void checkLine()
// 2008-09-24 H.Itou Add Start
     throws OAException
// 2008-09-24 H.Itou Add End
  {
// 2008-10-21 H.Itou Add Start 統合テスト指摘353
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    // 移動実績情報ヘッダVO取得
    OAViewObject hdrVo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow  hdrRow      = (OARow)hdrVo.first();
    // ************************ //
    // * 在庫クローズチェック * //
    // ************************ //
    stockCloseCheck(hdrVo, hdrRow, exceptions);

    // 在庫クローズエラーの場合、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
// 2008-10-21 H.Itou Add End

    // 品目格納用HashMap生成
    HashMap itemParams = new HashMap();
    // 移動実績情報VO取得
    OAViewObject vo = getXxinvMovementResultsLnVO1();
    // 1行目を取得
    vo.first();
    int i = 0;
    
    while (vo.getCurrentRow() != null)
    {
      OARow row = (OARow)vo.getCurrentRow();
      String itemCode = (String)row.getAttribute("ItemCode");
      
      // 品目取得
      String chkItem = (String)itemParams.get(itemCode);
      // 品目が取得できた場合
      if (!XxcmnUtility.isBlankOrNull(chkItem))
      {
        // エラーメッセージ出力
        throw new OAException(
                    XxcmnConstants.APPL_XXINV,
                    XxinvConstants.XXINV10063);
      
      } else
      {
        itemParams.put(itemCode, itemCode);
        // 品目が入力されていた場合
        if (!XxcmnUtility.isBlankOrNull(itemCode))
        {
          i++;
          row.setAttribute("LineNumber", new Number(i));
        }
      }
  
      vo.next();
    }
    // mod start ver1.3
    // 品目未入力チェック
    if (i == 0)
    {
      // トークン生成
      MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_ITEM, XxinvConstants.TOKEN_NAME_ITEM) };
      // エラーメッセージ出力
      throw new OAException(
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10061,
                  tokens);
    }
    // mod end ver1.3
  } // checkLine

  /***************************************************************************
   * 入出庫実績明細画面の登録・更新処理を行うメソッドです。
   * @return String リターンコード(正常(更新有)：MovHdrId、正常(更新無)：TRUE、エラー：FALSE)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public String doExecute() throws OAException
  {
    boolean lineExeFlag = false;
    String retCode = XxcmnConstants.STRING_TRUE;
    String insFlag  = XxcmnConstants.STRING_N;
    
    // 入出庫実績ヘッダ情報取得
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow movHdrRow    = (OARow)movementResultsHdVo.first();
    String processFlag = (String)movHdrRow.getAttribute("ProcessFlag");

    // 入出庫実績明細情報取得
    OAViewObject movementResultsLnVo = getXxinvMovementResultsLnVO1();
    // 1行目を取得
    movementResultsLnVo.first();

    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1行目を取得
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();
    String productFlg      = (String)resultsSearchRow.getAttribute("ProductFlg");

    // 更新の場合
    if (XxinvConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      // 移動明細更新処理
      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();
        
        // 新規登録の明細行の場合
        if ( XxinvConstants.PROCESS_FLAG_I.equals(movementResultsLnRow.getAttribute("ProcessFlag"))
         && !XxcmnUtility.isBlankOrNull(movementResultsLnRow.getAttribute("ItemCode")))
        {
          // 移動依頼/指示明細登録処理
          insertMovLine(movHdrRow, movementResultsLnRow);
        }
        movementResultsLnVo.next();
      }

      // 移動ヘッダ更新処理(正常(更新有)：MovHdrId、正常(更新無)：TRUE、エラー：FALSE)
      retCode = UpdateHdr();
      if (retCode.equals(XxcmnConstants.STRING_TRUE))
      {
        // 移動ヘッダIDを取得
        Number movHdrId = (Number)movHdrRow.getAttribute("MovHdrId");
        retCode         = XxcmnUtility.stringValue(movHdrId);
      }
      resultsSearchRow.setAttribute("ExeFlag", "1");
    // 新規登録登録の場合
    } else
    {
      // 移動ヘッダIDを取得
      Number movHdrId = XxinvUtility.getMovHdrId(getOADBTransaction());
      movHdrRow.setAttribute("MovHdrId", movHdrId);
      // 移動番号を取得
      String movNum = XxcmnUtility.getSeqNo(getOADBTransaction(), "移動番号");

      movHdrRow.setAttribute("MovNum",     movNum);
      movHdrRow.setAttribute("ProductFlg", productFlg);

      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

        // 品目が入力されていた場合
        if (!XxcmnUtility.isBlankOrNull(movementResultsLnRow.getAttribute("ItemCode")))
        {
          // 移動依頼/指示明細登録処理
          insertMovLine(movHdrRow, movementResultsLnRow);
          lineExeFlag = true;
        }

        movementResultsLnVo.next();
      }
      // 移動明細が登録されていた場合
      if (lineExeFlag)
      {

        // 移動依頼/指示ヘッダ登録処理
        insertMovHdr(movHdrRow);

        insFlag = XxcmnConstants.STRING_Y;
      }

      // 登録処理が正常に終了した場合、移動ヘッダIDを戻す
      if (XxcmnConstants.STRING_Y.equals(insFlag))
      {
        retCode = XxcmnUtility.stringValue(movHdrId);
        resultsSearchRow.setAttribute("ExeFlag", "1");

      // 登録無し終了した場合、STRING_TRUEを戻す
      } else
      {
        retCode = XxcmnConstants.STRING_TRUE;
      }
    }
    return retCode;
  } // doExecute

  /*****************************************************************************
   * 移動依頼/指示ヘッダ(アドオン)にデータを追加します。
   * @param hdrRow - ヘッダ行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void insertMovHdr(
    OARow hdrRow
  ) throws OAException
  {
    String apiName = "insertMovHdr";
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                     ");
    sb.append("  INSERT INTO xxinv_mov_req_instr_headers(");
    sb.append("    mov_hdr_id                 "); // 移動ヘッダID
    sb.append("   ,mov_num                    "); // 移動番号
    sb.append("   ,mov_type                   "); // 移動タイプ
    sb.append("   ,entered_date               "); // 入力日
    sb.append("   ,instruction_post_code      "); // 指示部署
    sb.append("   ,status                     "); // ステータス
    sb.append("   ,notif_status               "); // 通知ステータス
    sb.append("   ,shipped_locat_id           "); // 出庫元ID
    sb.append("   ,shipped_locat_code         "); // 出庫元保管場所
    sb.append("   ,ship_to_locat_id           "); // 入庫先ID
    sb.append("   ,ship_to_locat_code         "); // 入庫先保管場所
    sb.append("   ,schedule_ship_date         "); // 出庫予定日
    sb.append("   ,schedule_arrival_date      "); // 入庫予定日
    sb.append("   ,freight_charge_class       "); // 運賃区分
    sb.append("   ,collected_pallet_qty       "); // パレット回収枚数
    sb.append("   ,out_pallet_qty             "); // パレット枚数(出)
    sb.append("   ,in_pallet_qty              "); // パレット枚数(入)
    sb.append("   ,no_cont_freight_class      "); // 契約外運賃区分
    sb.append("   ,description                "); // 摘要
    sb.append("   ,organization_id            "); // 組織ID
    sb.append("   ,career_id                  "); // 運送業者ID
    sb.append("   ,freight_carrier_code       "); // 運送業者
    sb.append("   ,actual_career_id           "); // 運送業者ID_実績
    sb.append("   ,actual_freight_carrier_code"); // 運送業者_実績
    sb.append("   ,actual_shipping_method_code"); // 配送区分_実績
    sb.append("   ,arrival_time_from          "); // 着荷時間FROM
    sb.append("   ,arrival_time_to            "); // 着荷時間TO
    sb.append("   ,weight_capacity_class      "); // 重量容積区分
    sb.append("   ,actual_ship_date           "); // 出庫実績日
    sb.append("   ,actual_arrival_date        "); // 入庫実績日
    sb.append("   ,item_class                 "); // 商品区分
    sb.append("   ,product_flg                "); // 製品識別区分
    sb.append("   ,no_instr_actual_class      "); // 指示なし実績区分
    sb.append("   ,comp_actual_flg            "); // 実績計上済みフラグ
    sb.append("   ,correct_actual_flg         "); // 実績訂正フラグ
    sb.append("   ,screen_update_by           "); // 画面更新者
    sb.append("   ,screen_update_date         "); // 画面更新日時
    sb.append("   ,created_by                 "); // 作成者
    sb.append("   ,creation_date              "); // 作成日
    sb.append("   ,last_updated_by            "); // 最終更新者
    sb.append("   ,last_update_date           "); // 最終更新日
    sb.append("   ,last_update_login)         "); // 最終更新ログイン
    sb.append("  VALUES( ");
    sb.append("    :1 "                        ); // 移動ヘッダID
    sb.append("   ,:2 "                        ); // 移動番号
    sb.append("   ,:3 "                        ); // 移動タイプ
    sb.append("   ,SYSDATE "                   ); // 入力日
    sb.append("   ,:4 "                        ); // 指示部署
    sb.append("   ,'03' "                      ); // ステータス
    sb.append("   ,'40' "                      ); // 通知ステータス
    sb.append("   ,:5 "                        ); // 出庫元ID
    sb.append("   ,:6 "                        ); // 出庫元保管場所
    sb.append("   ,:7 "                        ); // 入庫先ID
    sb.append("   ,:8 "                        ); // 入庫先保管場所
    sb.append("   ,:9 "                        ); // 出庫予定日
    sb.append("   ,:10 "                       ); // 入庫予定日
    sb.append("   ,:11 "                       ); // 運賃区分
    sb.append("   ,:12 "                       ); // パレット回収枚数
    sb.append("   ,:13 "                       ); // パレット枚数(出)
    sb.append("   ,:14 "                       ); // パレット枚数(入)
    sb.append("   ,:15 "                       ); // 契約外運賃区分
    sb.append("   ,:16 "                       ); // 摘要
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') "); // 組織ID
    sb.append("   ,:17 "                       ); // 運送業者ID
    sb.append("   ,:18 "                       ); // 運送業者
    sb.append("   ,:19 "                       ); // 運送業者ID_実績
    sb.append("   ,:20 "                       ); // 運送業者_実績
    sb.append("   ,:21 "                       ); // 配送区分_実績
    sb.append("   ,:22 "                       ); // 着荷時間FROM
    sb.append("   ,:23 "                       ); // 着荷時間TO
    sb.append("   ,:24 "                       ); // 重量容積区分
    sb.append("   ,:25 "                       ); // 出庫実績日
    sb.append("   ,:26 "                       ); // 入庫実績日
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "); // 商品区分
    sb.append("   ,:27 "                       ); // 製品識別区分
    sb.append("   ,'Y' "                       ); // 指示なし実績区分
    sb.append("   ,'N' "                       ); // 実績計上済みフラグ
    sb.append("   ,'N' "                       ); // 実績訂正フラグ
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // 画面更新者
    sb.append("   ,SYSDATE "                   ); // 画面更新日時
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // 作成者
    sb.append("   ,SYSDATE "                   ); // 作成日
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // 最終更新者
    sb.append("   ,SYSDATE "                   ); // 最終更新日
    sb.append("   ,FND_GLOBAL.LOGIN_ID); "     ); // 最終更新ログイン
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // 情報を取得
      Number movHdrId                 = (Number)hdrRow.getAttribute("MovHdrId");                 // 移動ヘッダID
      String movNum                   = (String)hdrRow.getAttribute("MovNum");                   // 移動番号
      String movType                  = (String)hdrRow.getAttribute("MovType");                  // 移動タイプ
      String instructionPostCode      = (String)hdrRow.getAttribute("InstructionPostCode");      // 指示部署
      Number shippedLocatId           = (Number)hdrRow.getAttribute("ShippedLocatId");           // 出庫元ID
      String description1             = (String)hdrRow.getAttribute("ShippedLocatCode");         // 出庫元保管場所
      Number shipToLocatId            = (Number)hdrRow.getAttribute("ShipToLocatId");            // 入庫先ID
      String description2             = (String)hdrRow.getAttribute("ShipToLocatCode");          // 入庫先保管場所
      Date   scheduleShipDate         = (Date)hdrRow.getAttribute("ScheduleShipDate");           // 出庫予定日
      Date   scheduleArrivalDate      = (Date)hdrRow.getAttribute("ScheduleArrivalDate");        // 入庫予定日
      String freightChargeClass       = (String)hdrRow.getAttribute("FreightChargeClass");       // 運賃区分
      Number collectedPalletQty       = (Number)hdrRow.getAttribute("CollectedPalletQty");       // パレット回収枚数
      Number outPalletQty             = (Number)hdrRow.getAttribute("OutPalletQty");             // パレット枚数(出)
      Number inPalletQty              = (Number)hdrRow.getAttribute("InPalletQty");              // パレット枚数(入)
      String noContFreightClass       = (String)hdrRow.getAttribute("NoContFreightClass");       // 契約外運賃区分
      String description              = (String)hdrRow.getAttribute("Description");              // 摘要
      Number dctualCareerId           = (Number)hdrRow.getAttribute("ActualCareerId");           // 運送業者ID_実績
      String actualFreightCarrierCode = (String)hdrRow.getAttribute("ActualFreightCarrierCode"); // 運送業者_実績
      String actualShippingMethodCode = (String)hdrRow.getAttribute("ActualShippingMethodCode"); // 配送区分_実績
      String arrivalTimeFrom          = (String)hdrRow.getAttribute("ArrivalTimeFrom");          // 着荷時間FROM
      String arrivalTimeTo            = (String)hdrRow.getAttribute("ArrivalTimeTo");            // 着荷時間TO
      String weightCapacityClass      = (String)hdrRow.getAttribute("WeightCapacityClass");      // 重量容積区分
      Date   actualShipDate           = (Date)hdrRow.getAttribute("ActualShipDate");             // 出庫実績日
      Date   actualArrivalDate        = (Date)hdrRow.getAttribute("ActualArrivalDate");          // 入庫実績日
      String productFlg               = (String)hdrRow.getAttribute("ProductFlg");               // 製品識別区分

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(movHdrId));              // 移動ヘッダID
      cstmt.setString(i++, movNum);                                    // 移動番号
      cstmt.setString(i++, movType);                                   // 移動タイプ
      cstmt.setString(i++, instructionPostCode);                       // 指示部署
      cstmt.setInt(i++, XxcmnUtility.intValue(shippedLocatId));        // 出庫元ID
      cstmt.setString(i++, description1);                              // 出庫元保管場所
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToLocatId));         // 入庫先ID
      cstmt.setString(i++, description2);                              // 入庫先保管場所
      cstmt.setDate(i++, XxcmnUtility.dateValue(scheduleShipDate));    // 出庫予定日
      cstmt.setDate(i++, XxcmnUtility.dateValue(scheduleArrivalDate)); // 入庫予定日
      cstmt.setString(i++, freightChargeClass);                        // 運賃区分
      if (XxcmnUtility.isBlankOrNull(collectedPalletQty))
      {
        cstmt.setNull(i++, Types.INTEGER);                             // パレット回収枚数
      } else
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(collectedPalletQty));  // パレット回収枚数
      }
      if (XxcmnUtility.isBlankOrNull(outPalletQty))
      {
        cstmt.setNull(i++, Types.INTEGER);                             // パレット枚数(出)
      } else
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(outPalletQty));        // パレット枚数(出)
      }
      if (XxcmnUtility.isBlankOrNull(inPalletQty))
      {
        cstmt.setNull(i++, Types.INTEGER);                             // パレット枚数(入)
      } else
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(inPalletQty));         // パレット枚数(入)
      }
      cstmt.setString(i++, noContFreightClass);                        // 契約外運賃区分
      cstmt.setString(i++, description);                               // 摘要
    // mod start ver1.5
      // 運賃区分が：1(有)の場合
//      if (XxinvConstants.FREIGHT_CHARGE_CLASS_1.equals(freightChargeClass))
//      {
        cstmt.setInt(i++,    XxcmnUtility.intValue(dctualCareerId));    // 運送業者ID
        cstmt.setString(i++, actualFreightCarrierCode);              // 運送業者
        cstmt.setInt(i++,    XxcmnUtility.intValue(dctualCareerId));    // 運送業者ID_実績
        cstmt.setString(i++, actualFreightCarrierCode);              // 運送業者_実績
//      } else
//      {
//        cstmt.setNull(i++, Types.INTEGER);                           // 運送業者ID
//        cstmt.setNull(i++, Types.INTEGER);                           // 運送業者
//        cstmt.setNull(i++, Types.INTEGER);                           // 運送業者ID_実績
//        cstmt.setNull(i++, Types.INTEGER);                           // 運送業者_実績
//      }
    // mod end ver1.5
      cstmt.setString(i++, actualShippingMethodCode);                  // 配送区分_実績
      cstmt.setString(i++, arrivalTimeFrom);                           // 着荷時間FROM
      cstmt.setString(i++, arrivalTimeTo);                             // 着荷時間TO
      cstmt.setString(i++, weightCapacityClass);                       // 重量容積区分
      cstmt.setDate(i++,   XxcmnUtility.dateValue(actualShipDate));      // 出庫実績日
      cstmt.setDate(i++,   XxcmnUtility.dateValue(actualArrivalDate));   // 入庫実績日
      cstmt.setString(i++, productFlg);                                // 製品識別区分

      //PL/SQL実行
      cstmt.execute();

      // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
      XxinvUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                              XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                                XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovHdr

  /*****************************************************************************
   * 移動依頼/指示明細(アドオン)にデータを追加します。
   * @param hdrRow - ヘッダ行
   * @param linRow - 明細行
   * @throws OAException - OA例外
   ****************************************************************************/
  public void insertMovLine(
    OARow hdrRow,
    OARow linRow
  ) throws OAException
  {
    String apiName = "insertMovLine";
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                        ");
    sb.append("  lt_mov_line_id xxinv_mov_req_instr_lines.mov_line_id%TYPE; ");
    sb.append("BEGIN                                     ");
    sb.append("  SELECT xxinv_mov_line_s1.NEXTVAL        ");
    sb.append("  INTO   lt_mov_line_id                   ");
    sb.append("  FROM   DUAL;                            ");
                // 移動依頼/指示明細(アドオン)登録
    sb.append("  INSERT INTO xxinv_mov_req_instr_lines(");
    sb.append("    mov_line_id                "); // 移動明細ID
    sb.append("   ,mov_hdr_id                 "); // 移動ヘッダID
    sb.append("   ,line_number                "); // 明細番号
    sb.append("   ,organization_id            "); // 組織ID
    sb.append("   ,item_id                    "); // OPM品目ID
    sb.append("   ,item_code                  "); // 品目
    sb.append("   ,uom_code                   "); // 単位
    sb.append("   ,delete_flg                 "); // 取消フラグ
    sb.append("   ,created_by                 "); // 作成者
    sb.append("   ,creation_date              "); // 作成日
    sb.append("   ,last_updated_by            "); // 最終更新者
    sb.append("   ,last_update_date           "); // 最終更新日
    sb.append("   ,last_update_login)         "); // 最終更新ログイン
    sb.append("  VALUES( ");
    sb.append("    lt_mov_line_id "            ); // 移動明細ID
    sb.append("   ,:1 "                        ); // 移動ヘッダID
    sb.append("   ,:2 "                        ); // 明細番号
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') "); // 組織ID
    sb.append("   ,:3 "                        ); // OPM品目ID
    sb.append("   ,:4 "                        ); // 品目
    sb.append("   ,:5 "                        ); // 単位
    sb.append("   ,'N' "                       ); // 取消フラグ
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // 作成者
    sb.append("   ,SYSDATE "                   ); // 作成日
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // 最終更新者
    sb.append("   ,SYSDATE "                   ); // 最終更新日
    sb.append("   ,FND_GLOBAL.LOGIN_ID); "     ); // 最終更新ログイン
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // 情報を取得
      Number movHdrId   = (Number)hdrRow.getAttribute("MovHdrId");    // 移動ヘッダID
      Number lineNumber = (Number)linRow.getAttribute("LineNumber");  // 明細番号
      Number itemId     = (Number)linRow.getAttribute("ItemId");      // OPM品目ID
      String itemCode   = (String)linRow.getAttribute("ItemCode");    // 品目
      String uomCode    = (String)linRow.getAttribute("UomCode");     // 単位

      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setInt(i++, XxcmnUtility.intValue(movHdrId));   // 移動ヘッダID
      cstmt.setInt(i++, XxcmnUtility.intValue(lineNumber)); // 明細番号
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));     // OPM品目ID
      cstmt.setString(i++, itemCode);                       // 品目
      cstmt.setString(i++, uomCode);                        // 単位

      //PL/SQL実行
      cstmt.execute();

      // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
      // ロールバック
    XxinvUtility.rollBack(getOADBTransaction());
    XxcmnUtility.writeLog(getOADBTransaction(),
                            XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                                XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovLine

  /***************************************************************************
   * 移動ヘッダID取得処理を行うメソッドです。
   * @return Number 移動ヘッダID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public Number getHdrId() throws OAException
  {
    
    // 入出庫実績ヘッダ情報取得
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow movHdrRow = (OARow)movementResultsHdVo.first();
    Number movHdrId = (Number)movHdrRow.getAttribute("MovHdrId");


    return movHdrId;
  } // getHdrId

  /***************************************************************************
   * コミット処理を行うメソッドです。
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void doCommit() throws OAException
  {
    // コミット
    getOADBTransaction().commit();
// 2008/08/22 v1.6 Y.Yamamoto Mod Start
    // 変更に関する警告をクリア
    super.clearWarnAboutChanges();  
// 2008/08/22 v1.6 Y.Yamamoto Mod End
  } // doCommit

  /***************************************************************************
   * ロールバック処理を行うメソッドです。
   ***************************************************************************
   */
  public void doRollBack()
  {
    // ロールバック
    XxcmnUtility.rollBack(getOADBTransaction());
  }

// 2008/08/20 v1.6 Y.Yamamoto Mod Start
  /***************************************************************************
   * 変更に関する警告をセットします。
   ***************************************************************************
   */
  public void doWarnAboutChanges()
  {
    // 移動実績情報ヘッダVO取得
    OAViewObject hdrVo = getXxinvMovementResultsHdVO1();
    OARow hdrRow  = (OARow)hdrVo.first();

    // いづれかの項目に変更があった場合
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ActualShipDate"),     hdrRow.getAttribute("DbActualShipDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ActualArrivalDate"),  hdrRow.getAttribute("DbActualArrivalDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("CollectedPalletQty"), hdrRow.getAttribute("DbCollectedPalletQty"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("OutPalletQty"),       hdrRow.getAttribute("DbOutPalletQty"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("InPalletQty"),        hdrRow.getAttribute("DbInPalletQty"))) 
    {
      // 変更に関する警告を設定
      super.setWarnAboutChanges();  
    }
  } // doWarnAboutChanges

  /***************************************************************************
   * 入出庫実績明細画面のロット実績アイコンの切り替えを行うメソッドです。
   * @param searchParams - パラメータHashMap
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doLotSwitcher(
    HashMap searchParams
  ) throws OAException
  {
    // パラメータ取得
    String searchHdrId = (String)searchParams.get(XxinvConstants.URL_PARAM_SEARCH_MOV_ID);
    String productFlg  = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);

    String addRowOn    = "0";

    // 入出庫実績ヘッダVO取得
    OAViewObject makeHdrVO = getXxinvMovementResultsHdVO1();
    // 1行目を取得
    OARow makeHdrVORow = (OARow)makeHdrVO.first();

    // 入出庫実績明細:VO取得
    OAViewObject movementResultsLnVo = getXxinvMovementResultsLnVO1();
    // 1行目を取得
    movementResultsLnVo.first();

    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
      
    // 1行目を取得
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();
    String actualFlg  = (String)resultsSearchRow.getAttribute("ActualFlg");

    // ヘッダ変更がなかった場合
    if ((XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
                               makeHdrVORow.getAttribute("DbActualShipDate")))     // 出庫日(実績)：出庫日(実績)(DB)
     && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                               makeHdrVORow.getAttribute("DbActualArrivalDate")))  // 着日(実績)：着日(実績)(DB)
     && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                               makeHdrVORow.getAttribute("DbOutPalletQty")))       // パレット枚数(出)：パレット枚数(出)(DB)
     && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                               makeHdrVORow.getAttribute("DbInPalletQty"))))       // パレット枚数(入)：パレット枚数(入)(DB)
    {
      resultsSearchRow.setAttribute("ExeFlag", "1");
    // ヘッダに変更があった場合、出庫実績ロット画面、入庫実績ロット画面遷移不可。
    } else
    {
      resultsSearchRow.setAttribute("ExeFlag", null);
    }
    String exeFlg     = (String)resultsSearchRow.getAttribute("ExeFlag");

    // キーに値をセット
    resultsSearchRow.setAttribute("HdrId", searchHdrId);

    while (movementResultsLnVo.getCurrentRow() != null)
    {
      OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

      if (XxcmnUtility.isEquals(movementResultsLnRow.getAttribute("ItemCodeReadOnly"),Boolean.TRUE))
      {
        // 処理フラグ2:更新をセット
        movementResultsLnRow.setAttribute("ProcessFlag",      XxinvConstants.PROCESS_FLAG_U);
        // 品目の入力項目制御
        movementResultsLnRow.setAttribute("ItemCodeReadOnly", Boolean.TRUE);
        
        // 実績データ区分が:1(出庫実績)の場合
        if ("1".equals(actualFlg))
        {
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
          }
          movementResultsLnRow.setAttribute("ShipToLotSwitcher",    "ShipToLotDetailsDisable");

        // 実績データ区分が:2(入庫実績)の場合
        } else if ("2".equals(actualFlg))
        {
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");
          }
          movementResultsLnRow.setAttribute("ShippedLotSwitcher",  "ShippedLotDetailsDisable");
        }
        addRowOn = "0";
      } else
      {
        addRowOn = "1";
      }
      movementResultsLnVo.next();
    }

    if ("1".equals(addRowOn)) 
    {
      movementResultsLnVo.first();

      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

        movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
        movementResultsLnRow.setAttribute("ShipToLotSwitcher",  "ShipToLotDetailsDisable");

        movementResultsLnVo.next();
      }
    }
  } // doLotSwitcher
// 2008/08/20 v1.6 Y.Yamamoto Mod End
// 2009-02-26 v1.12 D.Nihei Add Start 本番障害#855対応 削除処理追加
  /*****************************************************************************
   * 指定された行を削除します。
   * @param exeType - 起動タイプ
   * @param movLineId - 移動明細ID
   * @param hdrParams - ヘッダ用HashMap
   * @param lnParams - 明細用HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public void chkDeleteLine(
    String movLineId
    ) throws OAException 
  {
    // 移動依頼/指示ヘッダVO
    XxinvMovementResultsHdVOImpl hdrVo = getXxinvMovementResultsHdVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    Number movHeaderId = (Number)hdrRow.getAttribute("MovHdrId");

    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);

    // ************************ //
    // * 在庫クローズチェック * //
    // ************************ //
    stockCloseCheck(hdrVo, hdrRow, exceptions);

    // 在庫クローズエラーの場合、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // 移動依頼/指示明細VO
    XxinvMovementResultsLnVOImpl vo = getXxinvMovementResultsLnVO1();
    // 削除対象行を取得
    OARow row = (OARow)vo.getFirstFilteredRow("MovLineId", new Number(Integer.parseInt(movLineId)));

    // 更新行取得
    Row[] rows = vo.getFilteredRows("ProcessFlag", XxinvConstants.PROCESS_FLAG_U);
    // 取得行の明細件数が1件しかない場合
    if ((rows == null) || (rows.length == 1)) 
    {
      Object itemCode = row.getAttribute("ItemCode");
      // 削除不可エラー
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "ItemCode",
                  itemCode,
                  XxcmnConstants.APPL_XXINV, 
                  XxinvConstants.XXINV10187);
    }
  } // chkDeleteLine

  /*****************************************************************************
   * 指定された行を削除します。
   * @param exeType - 起動タイプ
   * @param movLineId - 移動明細ID
   * @param hdrParams - ヘッダ用HashMap
   * @param lnParams - 明細用HashMap
   * @throws OAException - OA例外
   ****************************************************************************/
  public void doDeleteLine(
    String movLineId,
    HashMap hdrParams,
    HashMap lnParams
    ) throws OAException 
  {
    // 終了メッセージ格納
    ArrayList infoMsg = new ArrayList(100);

    // 移動依頼/指示ヘッダVO
    XxinvMovementResultsHdVOImpl hdrVo = getXxinvMovementResultsHdVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    Number movHeaderId = (Number)hdrRow.getAttribute("MovHdrId"); // 移動ヘッダID
    String movNum      = (String)hdrRow.getAttribute("MovNum");   // 移動番号
    String status      = (String)hdrRow.getAttribute("Status");   // ステータス

    // 移動依頼/指示ヘッダVOデータ取得
    HashMap params = new HashMap();
    params.put("MovHdrId",       movHeaderId);        // 移動ヘッダID
    params.put("LastUpdateDate", hdrRow.getAttribute("LastUpdateDate"));  // 最終更新日

    // 移動依頼/指示明細VO
    XxinvMovementResultsLnVOImpl vo = getXxinvMovementResultsLnVO1();
    // 削除対象行を取得
    OARow row = (OARow)vo.getFirstFilteredRow("MovLineId", new Number(Integer.parseInt(movLineId)));

    // 実績データ区分VO取得
    OAViewObject shVo = getXxinvMovResultsSearchVO1();
    OARow  shRow = (OARow)shVo.first(); 
    String actualFlg = (String)shRow.getAttribute("ActualFlg"); // 実績データ区分

    // ロック・排他処理
    chkLockAndExclusive(params);

    // 削除処理
    deleteMovLine(movHeaderId.toString(), movLineId);

    // 削除完了メッセージ登録
    MessageToken[] token = { new MessageToken(XxcmnConstants.TOKEN_PROCESS, XxinvConstants.TOKEN_NAME_DEL) };
    infoMsg.add(new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN05001,
                                token,
                                OAException.INFORMATION,
                                null));

    // ************************************** // 
    // *  全移動明細実績数量登録済チェック  * //
    // ************************************** //
    // 全移動明細出庫実績数量登録済チェック (true:登録済  false:未登録あり)
    boolean shippedResultFlag = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1");
    // 全移動明細入庫実績数量登録済チェック (true:登録済  false:未登録あり)
    boolean shipToResultFlag  = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2");

    // ************************************** // 
    // * ステータス判定                     * //
    // ************************************** //
    String updStatus = status;
    // 移動明細の出庫実績数量・入庫実績数量が共にすべて登録済の場合
    if (shippedResultFlag && shipToResultFlag)
    {
      updStatus = XxinvConstants.STATUS_06; // 06：入出庫報告有
    
    // 出庫実績メニューで起動で全ての出庫実績が入力されている場合
    } else if (XxinvConstants.ACTUAL_FLAG_DELI.equals(actualFlg) && shippedResultFlag)
    {
      // ステータスが 02：依頼済 OR 03：調整中 の場合
      if (XxinvConstants.STATUS_02.equals(status)
       || XxinvConstants.STATUS_03.equals(status))
      { 
        updStatus = XxinvConstants.STATUS_04; // 04：出庫報告有

      }

    // 入庫実績メニューで起動で全ての入庫実績が入力されている場合
    } else if (XxinvConstants.ACTUAL_FLAG_SCOC.equals(actualFlg) && shipToResultFlag)
    {
      // ステータスが 02：依頼済 OR 03：調整中 OR 05：入庫報告有 の場合
      if (XxinvConstants.STATUS_02.equals(status)
       || XxinvConstants.STATUS_03.equals(status))
      { 
        updStatus = XxinvConstants.STATUS_05; // 05：入庫報告有

      }
    }
    // ステータスに変更があった場合
    if (!XxcmnUtility.isEquals(status, updStatus)) 
    {
      // ************************************** // 
      // * ステータス更新                     * //
      // ************************************** //
      XxinvUtility.updateStatus(
        getOADBTransaction(),
        movHeaderId,
        updStatus);

    }

    // ************************************** // 
    // * コミット処理                       * //
    // ************************************** //
    doCommit();
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
//        infoMsg.add(new OAException(XxcmnConstants.APPL_XXINV,
//                                    XxinvConstants.XXINV10006,
//                                    tokens,
//                                    OAException.INFORMATION,
//                                    null));
//      }
//    }
// 2009-12-28 H.Itou Del End

    // ヘッダ初期化&再検索
    initializeHdr(hdrParams);
    doSearchHdr(movHeaderId.toString());

    // 明細初期化&再検索
    initializeLine(lnParams);
    doSearchLine(lnParams);
    
    // メッセージを出力し、処理終了
    OAException.raiseBundledOAException(infoMsg);

  } // doDeleteLine

  /*****************************************************************************
   * 移動依頼/指示明細(アドオン)にデータを削除します。
   * @param movLineId - 移動明細ID
   * @throws OAException - OA例外
   ****************************************************************************/
  public void deleteMovLine(
    String movHeaderId,
    String movLineId
  ) throws OAException
  {
    String apiName = "deleteMovLine";
    
    //PL/SQLの作成を行います
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxinv_mov_req_instr_lines l "); // 移動依頼/指示明細アドオン
    sb.append("  SET    l.delete_flg         = 'Y'                 "); // 削除フラグ
    sb.append("       , l.last_updated_by    = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("       , l.last_update_date   = SYSDATE             "); // 最終更新日
    sb.append("       , l.last_update_login  = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  l.mov_line_id = TO_NUMBER(:1) "); // 移動明細ID
    sb.append("  ; ");
    sb.append("  UPDATE xxinv_mov_req_instr_headers h "); // 移動依頼/指示ヘッダアドオン
    sb.append("  SET    h.sum_quantity       = (SELECT SUM(l.instruct_qty)         ");
    sb.append("                                 FROM   xxinv_mov_req_instr_lines l ");
    sb.append("                                 WHERE  l.mov_hdr_id = h.mov_hdr_id ");
    sb.append("                                 AND    l.delete_flg = 'N' )        "); // 合計数量
    sb.append("       , h.screen_update_by   = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("       , h.screen_update_date = SYSDATE             "); // 最終更新日
    sb.append("       , h.last_updated_by    = FND_GLOBAL.USER_ID  "); // 最終更新者
    sb.append("       , h.last_update_date   = SYSDATE             "); // 最終更新日
    sb.append("       , h.last_update_login  = FND_GLOBAL.LOGIN_ID "); // 最終更新ログイン
    sb.append("  WHERE  h.mov_hdr_id = TO_NUMBER(:2) "); // 移動ヘッダID
    sb.append("  ; ");
    sb.append("END; ");
    
    //PL/SQLの設定を行います
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      int i = 1;
      // パラメータ設定(INパラメータ)
      cstmt.setString(i++, movLineId);   // 移動明細ID
      cstmt.setString(i++, movHeaderId); // 移動ヘッダID

      //PL/SQL実行
      cstmt.execute();

      // PL/SQL実行時例外の場合
    } catch(SQLException s)
    {
        // ロールバック
      XxinvUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                              XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
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
        XxinvUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                                XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // deleteMovLine
// 2009-02-26 v1.12 D.Nihei Add End

  /**
   * 
   * Container's getter for XxinvMovementResultsVO1
   */
  public XxinvMovementResultsVOImpl getXxinvMovementResultsVO1()
  {
    return (XxinvMovementResultsVOImpl)findViewObject("XxinvMovementResultsVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovementResultsHdPVO1
   */
  public XxinvMovementResultsHdPVOImpl getXxinvMovementResultsHdPVO1()
  {
    return (XxinvMovementResultsHdPVOImpl)findViewObject("XxinvMovementResultsHdPVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovementResultsHdVO1
   */
  public XxinvMovementResultsHdVOImpl getXxinvMovementResultsHdVO1()
  {
    return (XxinvMovementResultsHdVOImpl)findViewObject("XxinvMovementResultsHdVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovementResultsLnVO1
   */
  public XxinvMovementResultsLnVOImpl getXxinvMovementResultsLnVO1()
  {
    return (XxinvMovementResultsLnVOImpl)findViewObject("XxinvMovementResultsLnVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovResultsHdSearchVO1
   */
  public XxinvMovResultsHdSearchVOImpl getXxinvMovResultsHdSearchVO1()
  {
    return (XxinvMovResultsHdSearchVOImpl)findViewObject("XxinvMovResultsHdSearchVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovementResultsLnPVO1
   */
  public XxinvMovementResultsLnPVOImpl getXxinvMovementResultsLnPVO1()
  {
    return (XxinvMovementResultsLnPVOImpl)findViewObject("XxinvMovementResultsLnPVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovResultsSearchVO1
   */
  public XxinvMovResultsSearchVOImpl getXxinvMovResultsSearchVO1()
  {
    return (XxinvMovResultsSearchVOImpl)findViewObject("XxinvMovResultsSearchVO1");
  }

}
