/*============================================================================
* ファイル名 : XxpoInspectLotSearchAMImpl
* 概要説明   : 検査ロット情報検索・登録アプリケーションモジュール
* バージョン : 1.6
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  戸谷田 大輔    新規作成
* 2008-05-09 1.1  熊本 和郎      内部変更要求#28,41,43対応
* 2008-12-24 1.2  二瓶大輔       本番障害#743対応
* 2009-02-06 1.3  伊藤ひとみ     本番障害#1147対応
* 2009-02-13 1.4  伊藤ひとみ     本番障害#1147対応
* 2009-02-17 1.5  伊藤ひとみ     本番障害#1096対応
* 2019-09-18 1.6  小路恭弘       E_本稼動_15887対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.xxpo370002j.server.XxpoLotsMstRegVOImpl;
import itoen.oracle.apps.xxpo.xxpo370002j.server.XxwipQtInspectionSummaryVOImpl;

import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import java.text.SimpleDateFormat;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * 検査ロット情報検索・登録画面のアプリケーションモジュールクラスです。
 * @author  ORACLE SCS
 * @version 1.4
 ***************************************************************************
 */
public class XxpoInspectLotSearchAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoInspectLotSearchAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo370001j.server",
                 "XxpoInspectLotSearchAMLocal");
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   ***************************************************************************
   */
  public void initialize()
  {
    // 表示用VOの取得
    OAViewObject dispVo = (OAViewObject)getXxpoDispInspectLotSummaryVO1();
    // 格納行定義
    Row dispRow = null;
    // 取引先情報取得メソッドの呼び出し
    // ユーザー情報取得 
    HashMap retHashMap = getUserData();

    if (dispVo.getFetchedRowCount() == 0)
    {
      dispVo.setMaxFetchSize(0);
      // 取引先、取引先名を格納
      dispRow = dispVo.createRow();      
      dispRow.setAttribute(
        "SearchVendorNo", (String)retHashMap.get("VendorCode"));

      if (!XxcmnUtility.isBlankOrNull(retHashMap.get("VendorId")))
      {
        try 
        {
          dispRow.setAttribute("SearchVendorId",
            new Number(retHashMap.get("VendorId")));
        } catch (SQLException s)
        {
          // 想定外エラー
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);        
        }       
      }
      dispRow.setAttribute(
        "SearchVendorName", (String)retHashMap.get("VendorName"));
      dispVo.insertRow(dispRow);        
    }
    // 1行目取得
    dispRow = (OARow)dispVo.first();
  }

  /***************************************************************************
   * ユーザー情報を取得するメソッドです。
   * @return ユーザー情報
   ***************************************************************************
   */
  public HashMap getUserData()
  {
    // ユーザー情報取得 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // トランザクション
                          );
    return retHashMap;
  }

  /***************************************************************************
   * 検索処理を行うメソッドです。
   ***************************************************************************
   */
  public void doSearch()
  {
    // 検査ロット情報検索VOの取得
    OAViewObject searchVo = (OAViewObject)getXxpoInspectLotSummaryVO1();
    OAViewObject dispVo = (OAViewObject)getXxpoDispInspectLotSummaryVO1();
    Row row = dispVo.getCurrentRow();
    // 検索条件
    String vendorCode = (String)row.getAttribute("SearchVendorNo");
    String vendorName = (String)row.getAttribute("SearchVendorName");
    String itemCode   = (String)row.getAttribute("SearchItemNo");
    String itemName   = (String)row.getAttribute("SearchItemShortName");
// mod start 1.1
//    oracle.jbo.domain.Number itemId
//            = (oracle.jbo.domain.Number)row.getAttribute("SearchItemId");
    Number itemId = (Number)row.getAttribute("SearchItemId");
// mod end 1.1
    String  lotNo     = (String)row.getAttribute("SearchLotNo");
    String  productFactory
            = (String)row.getAttribute("SearchAttribute20");
    String productLotNo = (String)row.getAttribute("SearchAttribute21");
// mod start 1.1
//    oracle.jbo.domain.Date  productDateFrom
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchAttribute1From");
//    oracle.jbo.domain.Date productDateTo
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchAttribute1To");
//    oracle.jbo.domain.Date creationDateFrom
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchCreationDateFrom");
//    oracle.jbo.domain.Date creationDateTo
//            = (oracle.jbo.domain.Date)row.getAttribute("SearchCreationDateTo");
//    oracle.jbo.domain.Number qtInspectReqNo
//            = (oracle.jbo.domain.Number)row.getAttribute("SearchQtInspectReqNo");

    Date  productDateFrom = (Date)row.getAttribute("SearchAttribute1From");
    Date productDateTo = (Date)row.getAttribute("SearchAttribute1To");
    Date creationDateFrom = (Date)row.getAttribute("SearchCreationDateFrom");
    Date creationDateTo = (Date)row.getAttribute("SearchCreationDateTo");
    Number qtInspectReqNo = (Number)row.getAttribute("SearchQtInspectReqNo");
// mod end 1.1

    // パラメータHashMapへ検索条件を格納
    HashMap searchParams = new HashMap();

    searchParams.put("vendorCode",       vendorCode);
    searchParams.put("vendorName",       vendorName);
    searchParams.put("itemCode",         itemCode);
    searchParams.put("itemName",         itemName);
    searchParams.put("itemId",           itemId);
    searchParams.put("lotNo",            lotNo);
    searchParams.put("productFactory",   productFactory);
    searchParams.put("productLotNo",     productLotNo);
    searchParams.put("productDateFrom",  productDateFrom);
    searchParams.put("productDateTo",    productDateTo);
    searchParams.put("creationDateFrom", creationDateFrom);
    searchParams.put("creationDateTo",   creationDateTo);
    searchParams.put("qtInspectReqNo",   qtInspectReqNo);

    // ****************************** //
    // *          検索実行           * //
    // ****************************** //
    // 引数の設定
    Serializable params[] = { searchParams };
    // 引数のデータ型を設定
    Class[] paramsType = { HashMap.class };
    searchVo.invokeMethod("initQuery", params, paramsType);
  }
  /***************************************************************************
   * 必須項目の入力チェックを行うメソッドです。
   ***************************************************************************
   */
  public void searchInputCheck()
  {
    // 変数定義
    OAViewObject vo = null;
    OARow row = null;
    String checkVendorCode = null;

    // 取引先を取得
    vo = (OAViewObject)getXxpoDispInspectLotSummaryVO1();
    row = (OARow)vo.getCurrentRow();
    checkVendorCode = (String)row.getAttribute("SearchVendorNo");

    // 取引先がNullの場合、OAAttrValExceptionをスロー
    if (XxcmnUtility.isBlankOrNull(checkVendorCode))
    {
      throw new OAAttrValException(
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "SearchVendorNo",
        row.getAttribute("SearchVendorNo"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002);
    }
  }
  /***************************************************************************
   * 検査ロット情報登録画面の初期設定処理を行うメソッドです。
   * @param lotId ロットID
   * @return 従業員情報
   ***************************************************************************
   */
  public HashMap initQuery(Number lotId)
  {
    // ユーザー情報取得 
    HashMap retHashMap = getUserData();    
    
    // VOの取得
// 2009-02-06 H.Itou Mod Start
//    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    XxpoLotsMstRegVOImpl registVo = getXxpoLotsMstRegVO1();
// 2009-02-06 H.Itou Mod End
// mod start 1.1
//    OAViewObject inspectVo = (OAViewObject)getXxwipQtInspectionSummaryVO1();
    XxwipQtInspectionSummaryVOImpl inspectVo = getXxwipQtInspectionSummaryVO1();
// mod end 1.1
    // ロットIDがNullの場合：新規
    if (XxcmnUtility.isBlankOrNull(lotId))
    {
// mod start 1.1
//      if (registVo.getFetchedRowCount() == 0)
//      {
//        registVo.setMaxFetchSize(0);
//      }
//      // 新規行(格納用)を作成する。
//      Row registRow = registVo.createRow();
//      registRow.setAttribute("Attribute8", retHashMap.get("VendorCode"));
//      registRow.setAttribute("VendorName", retHashMap.get("VendorName"));
//      registVo.insertRow(registRow);
      if (!registVo.isPreparedForExecution())
      {
        registVo.setWhereClauseParam(0,null);
        registVo.executeQuery();
        registVo.insertRow(registVo.createRow());
        // 1行目を取得
        OARow registRow = (OARow)registVo.first();
        // キーに値をセット
        registRow.setNewRowState(Row.STATUS_INITIALIZED);
        registRow.setAttribute("LotId", new Number(-1));
        registRow.setAttribute("Attribute8", retHashMap.get("VendorCode"));
        registRow.setAttribute("VendorName", retHashMap.get("VendorName"));
      }
// mod end 1.1

// mod start 1.1
//      if (inspectVo.getFetchedRowCount() == 0)
//      {
//        inspectVo.setMaxFetchSize(0);
//      }
//      // 新規行を作成する
//      Row inspectRow = inspectVo.createRow();
//      inspectVo.insertRow(inspectRow);
      if (!inspectVo.isPreparedForExecution())
      {
        inspectVo.setWhereClauseParam(0,null);
        inspectVo.executeQuery();
        inspectVo.insertRow(inspectVo.createRow());
        // 1行目を取得
        OARow inspectRow = (OARow)inspectVo.first();
        // キーに値をセット
        inspectRow.setNewRowState(Row.STATUS_INITIALIZED);
      }

// mod end 1.1
    // ロットIDがNullじゃない場合：更新
    } else 
    {
// 2009-02-06 H.Itou Mod Start
      // パラメータの設定
//      Serializable[] params = { new Number(lotId) };
//      Class[] paramTypes = { Number.class };
//
//      // 初期化処理(OPMロットマスタ登録VO)
//      registVo.setMaxFetchSize(1);
//
//      registVo.invokeMethod("initQuery", params, paramTypes);

      registVo.initQuery(new Number(lotId));

// 2009-02-06 H.Itou Mod End

      if (registVo.getRowCount() == 0)
      {
        // 想定外エラー
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
      }
      // 行を取得する。
// 2009-02-06 H.Itou Mod Start
//      Row registRow = registVo.first();
      OARow registRow = (OARow)registVo.first();
// 2009-02-06 H.Itou Mod End
      // 検査依頼Noの取得
      String insReqNo = (String)registRow.getAttribute("Attribute22");
// mod start 1.1
/*
      if (!XxcmnUtility.isBlankOrNull(insReqNo))
      {
        try{
          // パラメータの設定
          Serializable[] params2 = { new Number(insReqNo) };
          Class[] paramTypes2 = { Number.class };
          // 初期化処理(検査依頼情報アドオンVO)
          inspectVo.setMaxFetchSize(1);
          inspectVo.invokeMethod("initQuery", params2, paramTypes2);
        } catch (SQLException ex)
        {
          // 想定外エラー
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
        }
      }
*/
      inspectVo.initQuery(insReqNo);
// mod end 1.1
    }
    return retHashMap;
  }

  /***************************************************************************
   * 「適用」ボタン押下時の必須チェックを行うメソッドです。
   ***************************************************************************
   */
  public void inputCheck()
  {
    // VOの取得
    OAViewObject vo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 現在行の取得
    Row row = vo.getCurrentRow();

    // 例外出力用リストの定義
    List exceptions = new ArrayList();

    // 取引先が未入力
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("Attribute8")))
    {
      // 取引先名をNullに設定
      row.setAttribute("VendorName", null);

      exceptions.add( new OAAttrValException(         
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "Attribute8",
        row.getAttribute("Attribute8"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002));
    }
    // 品目が未入力
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("ItemNo")))
    {
      // 品目名・品目IDをNullに設定
      row.setAttribute("ItemShortName", null);
      row.setAttribute("ItemId", null);

      exceptions.add( new OAAttrValException(         
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "ItemNo",
        row.getAttribute("ItemNo"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002));
    }
    // 製造日/仕入日が未入力
    if (XxcmnUtility.isBlankOrNull(row.getAttribute("Attribute1")))
    {
      exceptions.add( new OAAttrValException(         
        OAException.TYP_VIEW_OBJECT,
        vo.getName(),
        row.getKey(),
        "Attribute1",
        row.getAttribute("Attribute1"),
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO10002));
    }
    // 例外の出力
    OAException.raiseBundledOAException(exceptions);

// 2009-02-06 H.Itou Mod Start 本番障害#1147
    // 品目未取得エラーチェック
    Date productedDate = (Date)row.getAttribute("Attribute1");
    Number itemId = (Number)row.getAttribute("ItemId");
    String itemCode = (String)row.getAttribute("ItemNo");

    XxpoUtility.getUseByDate(
                         getOADBTransaction(),  // トランザクション
                         itemId,                // 品目ID
                         productedDate,         // 製造日
                         itemCode
                         );
// 2009-02-06 H.Itou Mod End

  }

  /***************************************************************************
   * 賞味期限を取得するメソッドです。
   ***************************************************************************
   */
  public void getBestBeforeDate()
  {
    // 変数
    String txtBestBeforeDate = null;
    String txtproductedDate = null;
// mod start 1.1
//    oracle.jbo.domain.Date bestBeforeDate = null;
    Date bestBeforeDate = null;
// mod end 1.1    
    // 検査ロット情報:登録VO取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 1行目を取得
    Row registRow = registVo.first();
    // 製造日/仕入日を取得
// mod start 1.1
//    oracle.jbo.domain.Date productedDate 
//    = (oracle.jbo.domain.Date)registRow.getAttribute("Attribute1");
    Date productedDate = (Date)registRow.getAttribute("Attribute1");
// mod end 1.1
    Number itemId = (Number)registRow.getAttribute("ItemId");
// 2009-02-06 H.Itou Add Start 本番障害#1147
    String itemCode = (String)registRow.getAttribute("ItemNo");
// 2009-02-06 H.Itou Add End
// 2009-02-06 H.Itou Del Start 本番障害#1147
//    // 製造日/仕入日が設定されていない場合
//    if (XxcmnUtility.isBlankOrNull(productedDate))
//    {
//      // 賞味期限にNullを設定
//      registRow.setAttribute("Attribute3", null);
//
//    // 引数が設定されていない場合
//    } else if (XxcmnUtility.isBlankOrNull(itemId))
//    {
//      // 賞味期限に製造日/仕入日を設定
//      registRow.setAttribute("Attribute3", productedDate);
//
//    // 賞味期限取得処理
//    } else
//    {
// 2009-02-06 H.Itou Del End
      bestBeforeDate = XxpoUtility.getUseByDate(
                         getOADBTransaction(),  // トランザクション
                         itemId,                // 品目ID
                         productedDate,         // 製造日
// 2009-02-06 H.Itou Mod Start 本番障害#1147
//                         "dummy"               // 賞味期間(未使用)
                         itemCode
// 2009-02-06 H.Itou Mod End
                         );

      // 賞味期限を検査ロット情報:登録VOにセット
      registRow.setAttribute("Attribute3", bestBeforeDate);
// 2009-02-06 H.Itou Del Start 本番障害#1147
//    }
// 2009-02-06 H.Itou Del End
  }

  /***************************************************************************
   * 検査ロット情報、及び品質検査依頼情報の作成を行う処理です。
   * @return List ロットIDと検査依頼No.を格納
   * @throws OAException OA例外
   ***************************************************************************
   */
// 2009-02-17 H.Itou Mod Start
//  public List doInsert() throws OAException
  public ArrayList[] doInsert() throws OAException
// 2009-02-17 H.Itou Mod End
  {
    // 変数定義
    Number lotId = null;
    String lotNo = null;
    Number itemId = null;
    String itemCode = null;
    String testCode = null;
    int qtInspectReqNo = 0;

// 2009-02-17 H.Itou Del End
//    // 処理結果メッセージ格納用リストの定義
//    List exptArray = new ArrayList();
// 2009-02-17 H.Itou Del End
    // 戻り値用リストの定義
    ArrayList retArray = new ArrayList();

// 2009-02-17 H.Itou Add Start
    // 完了メッセージ
    ArrayList messages = new ArrayList();
// 2009-02-17 H.Itou Add End

    // トランザクションの取得
    OADBTransaction trans = getOADBTransaction();

    // セーブポイントの設定
    trans.executeCommand("SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);

    // VOの取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 現在行の取得
    Row registRow = registVo.getCurrentRow();

    // 画面項目の取得
    itemId = (Number)registRow.getAttribute("ItemId");
    itemCode = (String)registRow.getAttribute("ItemNo");

    // 試験有無区分
    testCode = getTestCode(itemCode);

    // ************************* //
    // *  ロット番号自動採番API  * //
    // ************************* //
    lotNo = generateLotNo(trans, itemId, itemCode);
    try
    {
      // ************************* //
      // *      ロット作成API     * //
      // ************************* //
      lotId = callCreateLot(trans, lotNo, testCode);
// 2009-02-17 H.Itou Add Start
      registRow.setAttribute("LotId", lotId); 
// 2009-02-17 H.Itou Add End
      // 戻り値リストにロットIDを追加
      retArray.add(lotId);

    } catch(OAException createLotExpt)
    {
      // ロールバックの実行
      trans.executeCommand(
        "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
      // Catchした例外をスローする
      throw createLotExpt;
    }
// 2009-02-17 H.Itou Add Start 本番障害#1096
    // ロット作成成功メッセージ
    MessageToken[] tokens = {
      new MessageToken("PROCESS", XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };

    messages.add(
      new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN05001,
        tokens,
        OAException.INFORMATION,
        null));
// 2009-02-17 H.Itou Add End
    // 品目に紐づく試験有無区分が「1(有)」の場合
    if ("1".equals(testCode))
    {
// 2009-02-17 H.Itou Mod Start 本番障害#1096
      // ******************************* //
      // * 品質検査依頼情報作成・更新  * //
      // ******************************* //
      callMakeQtInspection(messages);
//      try
//      {
//
//        // ************************* //
//        // * 品質検査依頼情報作成API * //
//        // ************************* //
//        qtInspectReqNo = callMakeQtInspection(trans,
//                                              lotId,
//                                              itemId,
//                                              0,
//                                              "insert"); 
//        // 戻り値リストに品質検査依頼No.を追加
//        retArray.add(new Number(qtInspectReqNo));
//
//      } catch(OAException makeQtInspectExpt)
//      {
//        // ロールバックの実行
//        trans.executeCommand(
//          "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
//
// 20080321 del yoshimoto Start
/*
        // メッセージをリストに追加
        // ロット情報作成成功メッセージ
        MessageToken[] tokens = { new MessageToken(
          "PROCESS", XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };

        exptArray.add(new OAException(
                        XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN05001,
                        tokens,
                        OAException.ERROR,
                        null));
*/
// 20080321 del yoshimoto End

//        // 品質検査依頼情報作成失敗メッセージ
//        exptArray.add(makeQtInspectExpt);
//
//        // 例外の出力
//        OAException.raiseBundledOAException(exptArray);
//      }
// 2009-02-17 H.Itou Mod End
    }
    // コミット
    trans.commit();
// 2009-02-17 H.Itou Mod Start
    // 戻り値
    ArrayList result[] = new ArrayList[2];
    result[0] = retArray; // 新規登録したロットID
    result[1] = messages; // 完了メッセージ
//    return retArray;
    return result;
// 2009-02-17 H.Itou Mod End
  }

  /***************************************************************************
   * 検査ロット情報、及び品質検査依頼情報の更新を行う処理です。
   * @throws OAException
   ***************************************************************************
   */
// 2009-02-17 H.Itou Mod Start
//  public List doUpdate() throws OAException
  public ArrayList doUpdate() throws OAException
// 2009-02-17 H.Itou Mod Start
  {
    // 変数定義
    Number lotId = null;
    String lotNo = null;
    Number itemId = null;
    String itemCode = null;
    String testCode = null;
    int qtInspectReqNo = 0;
    
    // 処理結果メッセージ格納用リストの定義
// 2009-02-17 H.Itou Mod Start
//    List exptArray = new ArrayList();
    ArrayList messages = new ArrayList();
// 2009-02-17 H.Itou Mod Start

    // 日付/時刻フォーマットサブクラス定義
    SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy/MM/dd");
    
    // VOの取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 現在行の取得
    Row registRow = registVo.getCurrentRow();
    
    // 画面項目の取得
    lotId = (Number)registRow.getAttribute("LotId");
    lotNo = (String)registRow.getAttribute("LotNo");
    itemId = (Number)registRow.getAttribute("ItemId");
    itemCode = (String)registRow.getAttribute("ItemNo");
    if (!XxcmnUtility.isBlankOrNull(registRow.getAttribute("Attribute22")))
    {
      qtInspectReqNo =
        Integer.parseInt((String)registRow.getAttribute("Attribute22"));      
    }

    // トランザクションの取得
    OADBTransaction trans = getOADBTransaction();

    // セーブポイントの設定
    trans.executeCommand("SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);

    // 試験有無区分
    testCode = getTestCode(itemCode);

    try 
    {
      // ロック処理
      getLotLock(trans, lotId, itemId);
      // 排他制御
      chkLotEexclusiveControl(trans, lotId, itemId);
      
      // ************************* //
      // *      ロット更新API     * //
      // ************************* //
      callUpdateLot(trans,
                    lotNo,
                    lotId,
                    itemId,
                    testCode);
      
    } catch (OAException updateLotExpt)
    {
      // ロールバック、コミット(ロックの解除)の実行
      trans.executeCommand(
        "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
      trans.commit();
      // 異常終了した場合、Catchした例外をスローする
      throw updateLotExpt;
    }
// 2009-02-17 H.Itou Add Start
    // ロット情報更新成功メッセージ
    MessageToken[] tokens = {
      new MessageToken("PROCESS",
                       XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };

    messages.add(
      new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN05001,
        tokens,
        OAException.INFORMATION,
        null));
// 2009-02-17 H.Itou Add End

    // 製造日/仕入日を取得
    Date attribute1Date =
      (Date)registRow.getAttribute("Attribute1");
    String txtAttribute1Date =
      (String)sdf1.format(attribute1Date.dateValue());
    String preAttribute1 =
      (String)registRow.getAttribute("PreAttribute1");

    // 製造日/仕入日が変更された場合
    if (!txtAttribute1Date.equals(preAttribute1))
    {
// 2009-02-17 H.Itou Add Start 本番障害#1096
      String createLotDiv = (String)registRow.getAttribute("Attribute24"); // 作成区分
// 2009-02-17 H.Itou Add End
      // 品目に紐づく試験有無区分が「1(有)」の場合
// 2009-02-17 H.Itou Mod Start 本番障害#1096
//      if ("1".equals(testCode))
      if ("1".equals(testCode)
        && "1".equals(createLotDiv)) // 作成区分が1:検査ロットの場合
// 2009-02-17 H.Itou Mod End
      {
// 2009-02-17 H.Itou Mod Start 本番障害#1096
      // ******************************* //
      // * 品質検査依頼情報作成・更新  * //
      // ******************************* //       
      callMakeQtInspection(messages);   
//        try
//        {
//          // ロック処理
//          getInspectLock(trans, qtInspectReqNo, lotId, itemId);
//          // 排他制御
//          chkInspectEexclusiveControl(trans, qtInspectReqNo, lotId, itemId);
//      
//          // ************************* //
//          // * 品質検査依頼情報更新API * //
//          // ************************* //        
//          qtInspectReqNo = callMakeQtInspection(trans,
//                                                lotId,
//                                                itemId,
//                                                qtInspectReqNo,
//                                                "update");                         
//        } catch(OAException makeQtInspectExpt)
//        {
//          // ロールバック、コミット(ロックの解除)の実行
//          trans.executeCommand(
//            "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
//          trans.commit();
//          
// 20080321 del yoshimoto Start
/*
          // メッセージの追加
          // ロット情報更新成功メッセージの追加
          MessageToken[] tokens = 
            { new MessageToken("PROCESS",
                               XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };

          exptArray.add(new OAException(
                          XxcmnConstants.APPL_XXCMN,
                          XxcmnConstants.XXCMN05001,
                          tokens,
                          OAException.ERROR,
                          null));
*/
// 20080321 del yoshimoto End
//
//          // 品質検査依頼情報更新失敗メッセージ           
//          exptArray.add(makeQtInspectExpt);
//
//          // 例外の出力
//          OAException.raiseBundledOAException(exptArray);
//        }
//        // 正常終了した場合、メッセージをリストに格納
//        // ロット情報更新成功メッセージ
//        MessageToken[] tokens = {
//          new MessageToken("PROCESS",
//                           XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };
//
//        exptArray.add(new OAException(
//                        XxcmnConstants.APPL_XXCMN,
//                        XxcmnConstants.XXCMN05001,
//                        tokens,
//                        OAException.INFORMATION,
//                        null));
//
//        // 品質検査依頼情報更新成功メッセージ
//        MessageToken[] tokens2 = { new MessageToken(
//          "PROCESS", XxpoConstants.TOKEN_NAME_UPDATE_QT_INSPECTION) };
//
//        exptArray.add(new OAException(
//                        XxcmnConstants.APPL_XXCMN,
//                        XxcmnConstants.XXCMN05001,
//                        tokens2,
//                        OAException.INFORMATION,
//                        null));
//        // コミット
//        trans.commit();
//
//        // メッセージの出力
//        return exptArray;
// 2009-02-17 H.Itou Mod End
      }
    }
// 2009-02-17 H.Itou Del Start
//    // ロット情報更新成功メッセージ
//    MessageToken[] tokens = {
//      new MessageToken("PROCESS", XxpoConstants.TOKEN_NAME_UPDATE_LOT_INFO) };
//
//    exptArray.add(new OAException(
//                    XxcmnConstants.APPL_XXCMN,
//                    XxcmnConstants.XXCMN05001,
//                    tokens,
//                    OAException.INFORMATION,
//                    null));
// 2009-02-17 H.Itou Del End
    // コミット
    trans.commit();
// 2009-02-17 H.Itou Mod Start
//    // メッセージの出力
//    return exptArray;
    return messages;
// 2009-02-17 H.Itou Mod End
  }

  /***************************************************************************
   * 品目に紐づく試験有無区分を取得します。
   * @param itemCode 品目コード
   * @return testCode 試験有無区分
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String getTestCode(String itemCode) throws OAException
  {
    // 変数定義
    String testCode = null;
    CallableStatement cstmt = null;
    String apiName = "getTestCode";

    // トランザクションの取得
    OADBTransaction trans = getOADBTransaction();

    // SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT ximv.test_code ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxcmn_item_mst_v ximv ");
    sb.append("  WHERE  ximv.item_no = :2; ");
    sb.append("END;");

    // SQLの設定
    cstmt = trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      cstmt.registerOutParameter(1, Types.VARCHAR);
      cstmt.setString(2, itemCode);

      // SQLの実行
      cstmt.execute();

      // 試験有無区分の取得
      testCode = cstmt.getString(1);

    } catch (SQLException expt)
    {
      // writeLog
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // 想定外エラー
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();
        } catch (SQLException expt2)
        {
          // writeLog
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN10123);
        }
      }
    }
    return testCode;
  }

  /***************************************************************************
   * ロット作成APIを呼び出します。
   * @param trans トランザクション
   * @param lotNo ロットNo
   * @param testCode 試験有無区分
   * @return lotId ロットID
   * @throws OAException OA例外
   ***************************************************************************
   */
  public Number callCreateLot(OADBTransaction trans,
                              String lotNo,
                              String testCode) throws OAException
  {
    // 変数定義
    String itemCode = null;
    Number itemId = null;
    String attribute1 = null;
    String attribute3 = null;
    String attribute8 = null;
    String attribute12 = null;
    String attribute14 = null;
    String attribute15 = null;
    String attribute18 = null;
    String attribute20 = null;
    String attribute21 = null;
    String attribute23 = null;
    String attribute24 = null;
    
    String retStatus = null;
    Number msgCount = null;
    String msgData = null;
    Number lotId = null;

    String apiName = "callCreateLot";
    
    // 日付/時刻フォーマットサブクラス定義
    SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy/MM/dd");

    // VOの取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 現在行の取得
    Row registRow = registVo.getCurrentRow();

    // Attribute3の取得
    java.sql.Date attr3 = XxcmnUtility.dateValue(
        (Date)registRow.getAttribute("Attribute3"));

    // 入力項目を取得
    itemCode = (String)registRow.getAttribute("ItemNo");
    attribute1 = sdf1.format(XxcmnUtility.dateValue(
      (Date)registRow.getAttribute("Attribute1")));
    if (!XxcmnUtility.isBlankOrNull(attr3))
    {
      // Nullでなければフォーマットする。
      attribute3 = sdf1.format(attr3); 
    }
    attribute8 = (String)registRow.getAttribute("Attribute8");
    attribute12 = (String)registRow.getAttribute("Attribute12");
    attribute14 = (String)registRow.getAttribute("Attribute14");
    attribute15 = (String)registRow.getAttribute("Attribute15");
    attribute18 = (String)registRow.getAttribute("Attribute18");
    attribute20 = (String)registRow.getAttribute("Attribute20");
    attribute21 = (String)registRow.getAttribute("Attribute21");
    // 作成区分には常に「1」を設定    
    attribute24 = "1";

    // 試験有無区分が「1(有)」の場合、ロットステータスに「10(未判定)」を設定
    if ("1".equals(testCode))
    {
      attribute23 = "10";
    // 試験有無区分が「0(無)」の場合、ロットステータスに「50(合格)」を設定
    } else if ("0".equals(testCode))
    {
      attribute23 = "50";
    }

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE");
    sb.append("  lr_create_lot         GMIGAPI.lot_rec_typ; ");
    sb.append("  lr_ic_lots_mst_row    ic_lots_mst%ROWTYPE; ");
    sb.append("  lr_ic_lots_cpg_row    ic_lots_cpg%ROWTYPE; ");
    sb.append("  ln_api_version_number CONSTANT NUMBER := 3.0; ");
    sb.append("  lb_setup_return_sts    BOOLEAN; ");
    sb.append("BEGIN"); 
    sb.append("  lb_setup_return_sts := GMIGUTL.Setup(FND_GLOBAL.USER_NAME); "); 
    sb.append("  lr_create_lot.item_no      := :1; "); // 品目コード
    sb.append("  lr_create_lot.lot_no       := :2; "); // ロットNo
    sb.append("  lr_create_lot.lot_created  := TRUNC(SYSDATE); "); // 作成日
// 2008-12-24 v.1.2 D.Nihei Add Start 本番障害#743
    sb.append("  lr_create_lot.expaction_date := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // 再テスト日付
    sb.append("  lr_create_lot.expire_date    := TO_DATE('2099/12/31', 'YYYY/MM/DD'); "); // 失効日付
// 2008-12-24 v.1.2 D.Nihei Add End
    sb.append("  lr_create_lot.inactive_ind := 0; "); // 有効
    sb.append("  lr_create_lot.origination_type := '0'; "); // 元タイプ
    sb.append("  lr_create_lot.attribute1   := :3; "); // 製造日/仕入日
    sb.append("  lr_create_lot.attribute3   := :4; "); // 賞味期限
    sb.append("  lr_create_lot.attribute8   := :5; "); // 取引先コード
    sb.append("  lr_create_lot.attribute12  := :6; "); // 産地
    sb.append("  lr_create_lot.attribute14  := :7; "); // ランク１
    sb.append("  lr_create_lot.attribute15  := :8; "); // ランク２
    sb.append("  lr_create_lot.attribute18  := :9; "); // 摘要
    sb.append("  lr_create_lot.attribute20  := :10; "); // 製造工場
    sb.append("  lr_create_lot.attribute21  := :11; "); // 製造ロット番号
    sb.append("  lr_create_lot.attribute23  := :12; "); // ロットステータス
    sb.append("  lr_create_lot.attribute24  := :13; "); // 作成区分
    sb.append("  GMIPAPI.CREATE_LOT ( ");
    sb.append("    ln_api_version_number ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_VALID_LEVEL_FULL ");
    sb.append("   ,lr_create_lot ");
    sb.append("   ,lr_ic_lots_mst_row ");
    sb.append("   ,lr_ic_lots_cpg_row ");
    sb.append("   ,:14 ");
    sb.append("   ,:15 ");
    sb.append("   ,:16 ); ");
    sb.append("  :17 := lr_ic_lots_mst_row.lot_id; ");
    sb.append("END; ");

    // PL/SQLの設定
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      // バインド変数に値を設定
      cstmt.setString(1, itemCode);
      cstmt.setString(2, lotNo);
      cstmt.setString(3, attribute1);
      cstmt.setString(4, attribute3);
      cstmt.setString(5, attribute8);
      cstmt.setString(6, attribute12);
      cstmt.setString(7, attribute14);
      cstmt.setString(8, attribute15);
      cstmt.setString(9, attribute18);
      cstmt.setString(10, attribute20);
      cstmt.setString(11, attribute21);
      cstmt.setString(12, attribute23);
      cstmt.setString(13, attribute24);
      cstmt.registerOutParameter(14, Types.VARCHAR);
      cstmt.registerOutParameter(15, Types.INTEGER);
      cstmt.registerOutParameter(16, Types.VARCHAR);
      cstmt.registerOutParameter(17, Types.INTEGER);

      // PL/SQLの実行
      cstmt.execute();
      // リターンコードの取得
      retStatus = cstmt.getString(14);

      // 正常終了の場合
      if (XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus))
      {
        // ロットIDを取得
        lotId = new Number(cstmt.getInt(17));

      // 異常終了の場合
      } else
      {
        // メッセージの出力
        MessageToken[] tokens = {
          new MessageToken("INFO_NAME", XxpoConstants.TOKEN_NAME_LOT_INFO) };
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10007,
          tokens,
          OAException.ERROR,
          null);
      }
    } catch(SQLException expt)
    {
      // writeLog
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // 想定外エラー
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();         
        } catch (SQLException expt2)
        {
          // writeLog
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          // 想定外エラー
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                        XxcmnConstants.XXCMN10123);
        }
      }
    }
    // ロットIDを返す
    return lotId;
  }

  /***************************************************************************
   * ロット更新APIを呼び出します。
   * @param trans トランザクション
   * @param lotNo ロットNo
   * @param lotId ロットID
   * @param itemId 品目ID
   * @param testCode 試験有無区分
   * @throws OAException OA例外
   ***************************************************************************
   */
  public void callUpdateLot(OADBTransaction trans,
                              String lotNo,
                              Number lotId,
                              Number itemId,
                              String testCode) throws OAException
  {
    // 変数定義
    String attribute1 = null;
    String attribute3 = null;
    String attribute12 = null;
    String attribute14 = null;
    String attribute15 = null;
    String attribute18 = null;
    String attribute20 = null;
    String attribute21 = null;
    
    String retStatus = null;
    Number msgCount = null;
    String msgData = null;
// add start 1.6
    String retCode = null;
// add end 1.6

    String apiName = "callUpdateLot";

    // 日付/時刻フォーマットサブクラス定義
    SimpleDateFormat sdf1 = new SimpleDateFormat("yyyy/MM/dd");

    // VOの取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 現在行の取得
    Row registRow = registVo.getCurrentRow();

    // java.sql.Dateに変換する。
    java.sql.Date attr3 = XxcmnUtility.dateValue(
// mod start 1.1
//      (oracle.jbo.domain.Date)registRow.getAttribute("Attribute3"));
      (Date)registRow.getAttribute("Attribute3"));
// mod end 1.1    
    // 入力項目を取得
    attribute1 = sdf1.format(XxcmnUtility.dateValue(
// mod start 1.1
//      (oracle.jbo.domain.Date)registRow.getAttribute("Attribute1")));
      (Date)registRow.getAttribute("Attribute1")));
// mod end 1.1
    if (!XxcmnUtility.isBlankOrNull(attr3)){
      // Nullでなければ、YYYY/MM/DDとする。
      attribute3 = sdf1.format(attr3);
    }
    attribute12 = (String)registRow.getAttribute("Attribute12");
    attribute14 = (String)registRow.getAttribute("Attribute14");
    attribute15 = (String)registRow.getAttribute("Attribute15");
    attribute18 = (String)registRow.getAttribute("Attribute18");
    attribute20 = (String)registRow.getAttribute("Attribute20");
    attribute21 = (String)registRow.getAttribute("Attribute21");

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("DECLARE");
    sb.append("  l_lot_rec            ic_lots_mst%ROWTYPE;");
    sb.append("  l_lot_cpg_rec        ic_lots_cpg%ROWTYPE;");
// add start 1.6
    sb.append("  l_before_lot_rec     ic_lots_mst%ROWTYPE;");
    sb.append("  cv_api_status_success CONSTANT VARCHAR2(1) := 'S'; ");
    sb.append("  cv_api_return_normal  CONSTANT VARCHAR2(1) := '0'; ");
// add end 1.6
    sb.append("  ln_api_version_number CONSTANT NUMBER := 1.0; ");
    sb.append("BEGIN ");
    sb.append("  SELECT * ");
    sb.append("  INTO   l_lot_rec ");
    sb.append("  FROM   ic_lots_mst    ilm ");
    sb.append("  WHERE  ilm.lot_no     = :1 ");
    sb.append("  AND    ilm.lot_id     = :2 ");
    sb.append("  AND    ilm.item_id    = :3; ");
// add start 1.6
    sb.append("  l_before_lot_rec           := l_lot_rec; ");
// add end 1.6
    sb.append("  l_lot_rec.attribute1       := :4; ");
    sb.append("  l_lot_rec.attribute3       := :5; ");
    sb.append("  l_lot_rec.attribute12      := :6; ");
    sb.append("  l_lot_rec.attribute14      := :7; ");
    sb.append("  l_lot_rec.attribute15      := :8; ");
    sb.append("  l_lot_rec.attribute18      := :9; ");
    sb.append("  l_lot_rec.attribute20      := :10; ");
    sb.append("  l_lot_rec.attribute21      := :11; ");
    sb.append("  l_lot_rec.last_updated_by  := :12; ");
    //sb.append("  l_lot_rec.last_update_date := TRUNC(SYSDATE); ");
    sb.append("  l_lot_rec.last_update_date := SYSDATE; ");     // 20080305 mod yoshimoto
    sb.append("  l_lot_cpg_rec.item_id      := l_lot_rec.item_id; ");
    sb.append("  l_lot_cpg_rec.lot_id           := l_lot_rec.lot_id; ");
    sb.append("  l_lot_cpg_rec.ic_hold_date     := TRUNC(SYSDATE); ");
    //sb.append("  l_lot_cpg_rec.last_update_date := TRUNC(SYSDATE); ");
    sb.append("  l_lot_cpg_rec.last_update_date := SYSDATE; "); // 20080305 mod yoshimoto
    sb.append("  l_lot_cpg_rec.last_updated_by  := :12; ");
    sb.append("  gmi_lotupdate_pub.update_lot ( ");
    sb.append("    ln_api_version_number ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_FALSE ");
    sb.append("   ,FND_API.G_VALID_LEVEL_FULL ");
    sb.append("   ,:13 ");
    sb.append("   ,:14 ");
    sb.append("   ,:15 ");
    sb.append("   ,l_lot_rec ");
    sb.append("   ,l_lot_cpg_rec); ");
// add start 1.6
    sb.append("  IF ( :13 = cv_api_status_success ) THEN ");
    sb.append("    IF ( NVL(l_lot_rec.attribute12 ,' ') <> NVL(l_before_lot_rec.attribute12  ,' ') ) THEN ");
    sb.append("      xxcmn_common_pkg.create_lot_mst_history( ");
    sb.append("        l_before_lot_rec, ");
    sb.append("        :16, ");
    sb.append("        :17, ");
    sb.append("        :18); ");
    sb.append("    ELSE ");
    sb.append("      :17 := cv_api_return_normal; ");
    sb.append("    END IF; ");
    sb.append("  END IF; ");
// add end 1.6
    sb.append("END; ");

    // PL/SQLの設定
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      // バインド変数に値を設定
      cstmt.setString(1, lotNo);
      cstmt.setInt(2, XxcmnUtility.intValue(lotId));
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));
      cstmt.setString(4, attribute1);
      cstmt.setString(5, attribute3);
      cstmt.setString(6, attribute12);
      cstmt.setString(7, attribute14);
      cstmt.setString(8, attribute15);
      cstmt.setString(9, attribute18);
      cstmt.setString(10, attribute20);
      cstmt.setString(11, attribute21);
      cstmt.setInt(12, trans.getUserId());
      cstmt.registerOutParameter(13, Types.VARCHAR);
      cstmt.registerOutParameter(14, Types.INTEGER);
      cstmt.registerOutParameter(15, Types.VARCHAR);
// add start 1.6
      cstmt.registerOutParameter(16, Types.VARCHAR);
      cstmt.registerOutParameter(17, Types.VARCHAR);
      cstmt.registerOutParameter(18, Types.VARCHAR);
// add end 1.6

      // PL/SQLの実行
      cstmt.execute();
      // リターンコードの取得
      retStatus = cstmt.getString(13);
// add start 1.6
      retCode   = cstmt.getString(17);
// add end 1.6
      
      // 異常終了の場合
      if (!XxcmnConstants.API_STATUS_SUCCESS.equals(retStatus))
      {
        // メッセージの出力
        MessageToken[] tokens =
          { new MessageToken("INFO_NAME", XxpoConstants.TOKEN_NAME_LOT_INFO),
            new MessageToken("PARAMETER", XxpoConstants.TOKEN_NAME_LOT_NO),
            new MessageToken("VALUE", lotNo) };

        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10006,
          tokens,
          OAException.ERROR,
          null);
// add start 1.6
      } else if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode))
      {
        // メッセージの出力
        MessageToken[] tokens =
          { new MessageToken("INFO_NAME", XxpoConstants.TAB_XXCMN_LOTS_MST_HISTORY) };

        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10007,
          tokens,
          OAException.ERROR,
          null);
// add end 1.6
      }
    } catch(SQLException expt)
    {
      // ログの取得
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // 想定外エラー
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();         
        } catch (SQLException expt2)
        {
          // ログの取得
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          // 想定外エラー
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * ロット番号の自動採番を行う処理です。
   * @param trans トランザクション
   * @param itemId 品目ID
   * @param itemCode 品目
   * @return lotNo ロットNo
   * @throws OAException OA例外
   ***************************************************************************
   */
  public String generateLotNo(OADBTransaction trans,
                              Number itemId,
                              String itemCode) throws OAException
  {
    // 変数定義
    String lotNo = null;
    String subLotNo = null;
    int retStatus = 5;  // 5：正常
    String apiName = "generateLotNo";

    // PL/SQL作成
    StringBuffer sb = new StringBuffer(100);

    sb.append("BEGIN ");
    sb.append("  gmi_autolot.generate_lot_number( ");
    sb.append("    :1 ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,null ");
    sb.append("   ,:2 ");
    sb.append("   ,:3 ");
    sb.append("   ,:4); ");
    sb.append("END; ");

    // PL/SQLの設定
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      // バインド変数に値を設定
      cstmt.setInt(1, XxcmnUtility.intValue(itemId));
      cstmt.registerOutParameter(2, Types.VARCHAR);
      cstmt.registerOutParameter(3, Types.VARCHAR);
      cstmt.registerOutParameter(4, Types.INTEGER);

      // PL/SQLの実行
      cstmt.execute();

      // 返り値を変数に格納
      lotNo = cstmt.getString(2);
      subLotNo = cstmt.getString(3);
      retStatus = cstmt.getInt(4);
      // ロットの自動採番に失敗した場合
      if (XxcmnUtility.isBlankOrNull(lotNo))
      {
        // ロールバックの実行
// mod start 1.1
//        trans.rollback();
        trans.executeCommand("ROLLBACK TO " + XxpoConstants.SAVE_POINT_XXPO370002J);
// mod end 1.1
        // エラーメッセージの出力
        MessageToken[] tokens = { new MessageToken("ITEM_NO", itemCode) };

        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10110,
          tokens,
          OAException.ERROR,
          null);
      }

    } catch(SQLException expt)
    {
      // ロールバックの実行
// mod start 1.1
//      trans.rollback();
      trans.executeCommand("ROLLBACK TO " + XxpoConstants.SAVE_POINT_XXPO370002J);
// mod end 1.1
      // ログの取得
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);
      // 想定外エラー
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();
        } catch (SQLException expt2)
        {
          // ロールバックの実行
// mod start 1.1
//          trans.rollback();
          trans.executeCommand("ROLLBACK TO " + XxpoConstants.SAVE_POINT_XXPO370002J);
// mod end 1.1
          // ログの取得
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);
          // 想定外エラー
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
    // 取得したロットNoを返す
    return lotNo;
  }

  /***************************************************************************
   * 品質検査依頼情報の作成/更新を行う処理です。
   * @param message - メッセージ
   * @throws OAException OA例外
   ***************************************************************************
   */
// 2009-02-17 H.Itou Mod Start 本番障害#1096
//  public int callMakeQtInspection(OADBTransaction trans,
//                                     Number lotId,
//                                     Number itemId,
//                                     int    pQtInspectReqNo,
//                                     String chkInsUpd) throws OAException
  public void callMakeQtInspection(ArrayList message) throws OAException
// 2009-02-17 H.Itou Mod End
  {
// 2009-02-17 H.Itou Add Start 本番障害#1096
    // トランザクション取得
    OADBTransaction trans = getOADBTransaction();
    // VOの取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    // 現在行の取得
    Row registRow = registVo.getCurrentRow();
    
    Number lotId  = (Number)registRow.getAttribute("LotId");  // ロットID
    Number itemId = (Number)registRow.getAttribute("ItemId"); // 品目ID
    int pQtInspectReqNo;
// 2009-02-17 H.Itou Add End

    // 変数定義
    int rQtInspectReqNo = 0;
    String retCode = null;
    String apiName = "callMakeQtInspection";

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(100);

    sb.append("BEGIN ");
    sb.append("  xxwip_common_pkg.make_qt_inspection( ");
    sb.append("    '3'");
    sb.append("   ,:1");
    sb.append("   ,:2");
    sb.append("   ,:3");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,null");
    sb.append("   ,:4");
    sb.append("   ,:5");
    sb.append("   ,:6");
    sb.append("   ,:7");
    sb.append("   ,:8);");
    sb.append("END;");

    // PL/SQLの設定
    CallableStatement cstmt =
      trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    // 作成の場合
// 2009-02-17 H.Itou Mod Start 本番障害#1096
//    if ("insert".equals(chkInsUpd))
    if (XxcmnUtility.isBlankOrNull(registRow.getAttribute("Attribute22")))
// 2009-02-17 H.Itou Mod End
    {
      try
      {
        // バインド変数に値を設定
        cstmt.setString(1, "1");
        cstmt.setInt(2, XxcmnUtility.intValue(lotId));
        cstmt.setInt(3, XxcmnUtility.intValue(itemId));
        cstmt.setNull(4, Types.INTEGER);
        cstmt.registerOutParameter(5, Types.INTEGER);
        cstmt.registerOutParameter(6, Types.VARCHAR);
        cstmt.registerOutParameter(7, Types.VARCHAR);
        cstmt.registerOutParameter(8, Types.VARCHAR);

        // PL/SQLの実行
        cstmt.execute();
        // リターンコードを取得
        retCode = cstmt.getString(7);

        // 正常終了
        if ("0".equals(retCode))
        {
// 2009-02-17 H.Itou Add Start
          // 品質検査依頼情報作成成功メッセージ
          MessageToken[] tokens =
            { new MessageToken("PROCESS", XxpoConstants.TOKEN_NAME_CREATE_QT_INSPECTION) };

          message.add(
            new OAException(
              XxcmnConstants.APPL_XXCMN,
              XxcmnConstants.XXCMN05001,
              tokens,
              OAException.INFORMATION,
              null));
// 2009-02-17 H.Itou Add End
// 2009-02-17 H.Itou Del Start
          // 検査依頼Noを取得
//          rQtInspectReqNo = cstmt.getInt(5);
// 2009-02-17 H.Itou Del End

        // 異常終了
        } else
        {
// 2009-02-17 H.Itou Add Start
        // ロールバックの実行
        trans.executeCommand(
          "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
// 2009-02-17 H.Itou Add End

          // エラーメッセージ出力
          MessageToken[] tokens = { 
            new MessageToken("INFO_NAME",
                             XxpoConstants.TOKEN_NAME_QT_INSPECTION_INFO) };

          throw new OAException(
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10007,
            tokens,
            OAException.ERROR,
            null);

        }
      } catch(SQLException expt)
      {
// 2009-02-17 H.Itou Add Start
        // ロールバックの実行
        trans.executeCommand(
          "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
// 2009-02-17 H.Itou Add End
        throw OAException.wrapperException(expt);

      } finally
      {
        if (cstmt != null)
        {
          try
          {
            cstmt.close();
          
          } catch (SQLException expt2)
          {
// 2009-02-17 H.Itou Add Start
            // ロールバックの実行
            trans.executeCommand(
              "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
// 2009-02-17 H.Itou Add End
            // ログの取得
            XxcmnUtility.writeLog(
              trans,
              XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
              expt2.toString(),
              6);
            // 想定外エラー
            throw new OAException(XxcmnConstants.APPL_XXCMN,
                                  XxcmnConstants.XXCMN10123);          }
        }
      }

    // 更新の場合
// 2009-02-17 H.Itou Mod Start 本番障害#1096
//    } else if ("update".equals(chkInsUpd))
    } else
// 2009-02-17 H.Itou Mod End
    {
      try
      {
// 2009-02-17 H.Itou Add Start 本番障害#1096
        // 検査依頼No取得
        pQtInspectReqNo =
          Integer.parseInt((String)registRow.getAttribute("Attribute22"));

        // ロック処理
        getInspectLock(trans, pQtInspectReqNo, lotId, itemId);

        // 排他制御
        chkInspectEexclusiveControl(trans, pQtInspectReqNo, lotId, itemId);
// 2009-02-17 H.Itou Add End

        // バインド変数に値を設定
        cstmt.setString(1, "2");
        cstmt.setInt(2, XxcmnUtility.intValue(lotId));
        cstmt.setInt(3, XxcmnUtility.intValue(itemId));
        cstmt.setInt(4, pQtInspectReqNo);
        cstmt.registerOutParameter(5, Types.INTEGER);
        cstmt.registerOutParameter(6, Types.VARCHAR);
        cstmt.registerOutParameter(7, Types.VARCHAR);
        cstmt.registerOutParameter(8, Types.VARCHAR);

        // PL/SQLの実行
        cstmt.execute();
        // リターンコードを取得
        retCode = cstmt.getString(7);

        if ("0".equals(retCode))
        {
// 2009-02-17 H.Itou Add Start
          // 品質検査依頼情報更新成功メッセージ
          MessageToken[] tokens =
            { new MessageToken("PROCESS", XxpoConstants.TOKEN_NAME_UPDATE_QT_INSPECTION) };

          message.add(
            new OAException(
              XxcmnConstants.APPL_XXCMN,
              XxcmnConstants.XXCMN05001,
              tokens,
              OAException.INFORMATION,
              null));
// 2009-02-17 H.Itou Add End
// 2009-02-17 H.Itou Del Start
//          // 検査依頼Noを取得
//          rQtInspectReqNo = cstmt.getInt(5);
// 2009-02-17 H.Itou Del End

        } else
        {
// 2009-02-17 H.Itou Add Start
          // ロールバックの実行
          trans.executeCommand(
            "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
// 2009-02-17 H.Itou Add End
          // エラーメッセージ出力
          MessageToken[] tokens = {
            new MessageToken(
              "INFO_NAME", XxpoConstants.TOKEN_NAME_QT_INSPECTION_INFO),
            new MessageToken(
              "PARAMETER", XxpoConstants.TOKEN_NAME_REQ_NO),
            new MessageToken(
              "VALUE", String.valueOf(pQtInspectReqNo)) };

          throw new OAException(
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10006,
            tokens,
            OAException.ERROR,
            null);
        }
      } catch(SQLException expt)
      {
// 2009-02-17 H.Itou Add Start
        // ロールバックの実行
        trans.executeCommand(
          "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
// 2009-02-17 H.Itou Add End
        // ログの取得
        XxcmnUtility.writeLog(
          trans,
          XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
          expt.toString(),
          6);
        // 想定外エラー
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123); 

      } finally
      {
        if (cstmt != null)
        {
          try
          {
            cstmt.close();
          } catch (SQLException expt2)
          {
// 2009-02-17 H.Itou Add Start
            // ロールバックの実行
            trans.executeCommand(
              "ROLLBACK TO SAVEPOINT " + XxpoConstants.SAVE_POINT_XXPO370002J);
// 2009-02-17 H.Itou Add End
            // ログの取得
            XxcmnUtility.writeLog(
              trans,
              XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
              expt2.toString(),
              6);
            // 想定外エラー
            throw new OAException(XxcmnConstants.APPL_XXCMN,
                                  XxcmnConstants.XXCMN10123); 
          }
        }
      }
    }
// 2009-02-17 H.Itou Del Start
//    // 検査依頼Noを返す
//    return rQtInspectReqNo;
// 2009-02-17 H.Itou Del End
  }

  /***************************************************************************
   * OPMロットマスタのロック処理を行うメソッドです。
   * @param trans トランザクション
   * @param lotId - ロットID
   * @param itemId - 品目ID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getLotLock(OADBTransaction trans,
                         Number lotId,
                         Number itemId) throws OAException 
  {
    String apiName = "getLotLock";

    // SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT ilm.lot_id ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   ic_lots_mst ilm ");
    sb.append("  WHERE  ilm.lot_id  = :2 ");
    sb.append("  AND    ilm.item_id = :3 ");
    sb.append("  FOR UPDATE NOWAIT; ");
    sb.append("END; ");

    // SQLの設定
    CallableStatement cstmt = trans.createCallableStatement(
      sb.toString(), trans.DEFAULT);

    // SQLの実行
    try 
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(lotId));
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));
      cstmt.execute();

    } catch (SQLException lockExpt)
    {
      // ログの取得
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        lockExpt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();

        } catch (SQLException expt)
        {
          // ログの取得
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * 品質検査依頼情報アドオンのロック処理を行うメソッドです。
   * @param trans トランザクション
   * @param reqNo - 検査依頼No.
   * @param lotId - ロットID
   * @param itemId - 品目ID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void getInspectLock(OADBTransaction trans,
                             int reqNo,
                             Number lotId,
                             Number itemId) throws OAException 
  {
    String apiName = "getInspectLock";

    // SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT xqi.qt_inspect_req_no req_no ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwip_qt_inspection xqi ");
    sb.append("        ,ic_lots_mst ilm ");
    sb.append("  WHERE  xqi.qt_inspect_req_no = :2 ");
    sb.append("  AND    xqi.qt_inspect_req_no = ilm.attribute22 ");
    sb.append("  AND    ilm.lot_id            = :3 ");
    sb.append("  AND    ilm.item_id           = :4 ");
    sb.append("  FOR UPDATE NOWAIT; ");
    sb.append("END; ");

    // SQLの設定
    CallableStatement cstmt = trans.createCallableStatement(
      sb.toString(), trans.DEFAULT);

    // SQLの実行
    try 
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, reqNo);
      cstmt.setInt(3, XxcmnUtility.intValue(lotId));
      cstmt.setInt(4, XxcmnUtility.intValue(itemId));
      cstmt.execute();

    } catch (SQLException lockExpt)
    {
      // ログの取得
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        lockExpt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();
        } catch (SQLException expt)
        {
          // ログの取得
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * OPMロットマスタにおける排他制御チェックを行うメソッドです。
   * @param trans トランザクション
   * @pstsm lotId ロットID
   * @param itemId 品目ID
   ***************************************************************************
   */
  public void chkLotEexclusiveControl(OADBTransaction trans,
                                      Number lotId,
                                      Number itemId)
  {
    // 変数定義
    String apiName = "chkLotEexclusiveControl";
    CallableStatement cstmt = null;

    // VOの取得
    OAViewObject registVo = (OAViewObject)getXxpoLotsMstRegVO1();
    OARow registRow = (OARow)registVo.first();

    // 画面項目の取得
    String lastUpdateDate =
      (String)registRow.getAttribute("IlmLastUpdateDate");

    // SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT COUNT(ilm.lot_id) cnt ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   ic_lots_mst ilm ");
    sb.append("  WHERE  ilm.lot_id = :2 ");
    sb.append("  AND    ilm.item_id = :3 ");
    sb.append("  AND    TO_CHAR(ilm.last_update_date, 'YYYY/MM/DD HH24:MI:SS') = :4 ");
    sb.append("  AND    ROWNUM     = 1; ");
    sb.append("END; ");

    // SQLの設定
    cstmt = getOADBTransaction().createCallableStatement(
      sb.toString(),getOADBTransaction().DEFAULT);

    try
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, XxcmnUtility.intValue(lotId));
      cstmt.setInt(3, XxcmnUtility.intValue(itemId));
      cstmt.setString(4, lastUpdateDate);

      // SQLの実行
      cstmt.execute();      
      
      // 排他エラーの場合
      if (cstmt.getInt(1) == 0)
      {
        // メッセージの出力
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }
    } catch (SQLException expt)
    {
      // ログの取得
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();

        } catch (SQLException expt2)
        {
          // ログの取得
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /***************************************************************************
   * 品質検査依頼情報アドオンにおける排他制御チェックを行うメソッドです。
   * @param trans トランザクション
   * @param qtInspectReqNo 検査依頼No.
   * @param lotId ロットID
   * @param itemId 品目ID
   ***************************************************************************
   */
  public void chkInspectEexclusiveControl(OADBTransaction trans,
                                          int qtInspectReqNo,
                                          Number lotId,
                                          Number itemId)
  {
    // 変数定義
    String apiName = "chkInspectEexclusiveControl";
    CallableStatement cstmt = null;

    // VOの取得
    OAViewObject inspectVo = (OAViewObject)getXxwipQtInspectionSummaryVO1();
    OARow inspectRow = (OARow)inspectVo.first();

    // 画面項目の取得
    String lastUpdateDate =
      (String)inspectRow.getAttribute("XqiLastUpdateDate");

    // PL/SQLの作成
    StringBuffer sb = new StringBuffer(1000);

    sb.append("BEGIN ");
    sb.append("  SELECT COUNT(xqi.qt_inspect_req_no) cnt ");
    sb.append("  INTO   :1 ");
    sb.append("  FROM   xxwip_qt_inspection xqi ");
    sb.append("        ,ic_lots_mst ilm ");
    sb.append("  WHERE  xqi.qt_inspect_req_no = :2 ");
    sb.append("  AND    xqi.qt_inspect_req_no = ilm.attribute22 ");
    sb.append("  AND    ilm.lot_id = :3 ");
    sb.append("  AND    ilm.item_id = :4 ");
    sb.append("  AND    TO_CHAR(xqi.last_update_date, 'YYYY/MM/DD HH24:MI:SS') = :5 ");
    sb.append("  AND    ROWNUM     = 1; ");
    sb.append("END; ");

    // PL/SQLの設定
    cstmt = trans.createCallableStatement(sb.toString(), trans.DEFAULT);

    try
    {
      cstmt.registerOutParameter(1, Types.INTEGER);
      cstmt.setInt(2, qtInspectReqNo);
      cstmt.setInt(3, XxcmnUtility.intValue(lotId));
      cstmt.setInt(4, XxcmnUtility.intValue(itemId));
      cstmt.setString(5, lastUpdateDate);

      // SQLの実行
      cstmt.execute();

      // 排他エラーの場合
      if (cstmt.getInt(1) == 0)
      {
        // メッセージの出力
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }
    } catch (SQLException expt)
    {
      // ログの取得
      XxcmnUtility.writeLog(
        trans,
        XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
        expt.toString(),
        6);

      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      if (cstmt != null)
      {
        try
        {
          cstmt.close();

        } catch (SQLException expt2)
        {
          // ログの取得
          XxcmnUtility.writeLog(
            trans,
            XxpoConstants.CLASS_AM_XXPO370002J + XxcmnConstants.DOT + apiName,
            expt2.toString(),
            6);

          throw new OAException(XxcmnConstants.APPL_XXCMN,
                                XxcmnConstants.XXCMN10123);
        }
      }
    }
  }

  /**
   * 
   * Container's getter for XxpoInspectLotSummaryVO1
   */
  public XxpoInspectLotSummaryVOImpl getXxpoInspectLotSummaryVO1()
  {
    return (XxpoInspectLotSummaryVOImpl)findViewObject(
             "XxpoInspectLotSummaryVO1");
  }




  /**
   * 
   * Container's getter for XxpoLotsMstRegVO1
   */
  public XxpoLotsMstRegVOImpl getXxpoLotsMstRegVO1()
  {
    return (XxpoLotsMstRegVOImpl)findViewObject("XxpoLotsMstRegVO1");
  }

  /**
   * 
   * Container's getter for XxwipQtInspectionSummaryVO1
   */
  public XxwipQtInspectionSummaryVOImpl getXxwipQtInspectionSummaryVO1()
  {
    return (XxwipQtInspectionSummaryVOImpl)findViewObject("XxwipQtInspectionSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxpDispoInspectLotSummaryVO1
   */
  public XxpoDispInspectLotSummaryVOImpl getXxpoDispInspectLotSummaryVO1()
  {
    return (XxpoDispInspectLotSummaryVOImpl)findViewObject("XxpoDispInspectLotSummaryVO1");
  }



}