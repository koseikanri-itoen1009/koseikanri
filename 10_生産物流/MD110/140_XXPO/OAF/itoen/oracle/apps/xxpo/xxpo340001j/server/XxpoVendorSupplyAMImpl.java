/*============================================================================
* ファイル名 : XxpoVendorSupplyAMImpl
* 概要説明   : 外注出来高報告アプリケーションモジュール
* バージョン : 1.7
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-11 1.0  伊藤ひとみ   新規作成
* 2008-05-07 1.0  伊藤ひとみ   変更要求対応(#86,90)、内部変更要求対応(#28,29,41)
* 2008-05-15 1.0  伊藤ひとみ   結合バグ#340_2
*                              外部ユーザーの場合、表示された取引先コードで検索できない。
* 2008-05-21 1.0  伊藤ひとみ   内部変更要求対応(#104)
* 2008-07-11 1.1  二瓶大輔     ST#421対応
* 2008-07-22 1.2  伊藤ひとみ   内部課題#32対応 換算ありの場合、ケース入数がNULLまたは0はエラー
* 2008-10-23 1.3  伊藤ひとみ   T_TE080_BPO_340 指摘5
* 2009-02-06 1.4  伊藤ひとみ   本番障害#1147対応
* 2009-02-18 1.5  伊藤ひとみ   本番障害#1096,1178対応
* 2009-03-02 1.6  伊藤ひとみ   本番障害#32対応
* 2015-10-06 1.7  山下翔太     E_本稼動_13238対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

import java.lang.Double;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 外注出来高報告のアプリケーションモジュールクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.7
 ***************************************************************************
 */
public class XxpoVendorSupplyAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoVendorSupplyAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo340001j.server", "XxpoVendorSupplyAMLocal");
  }

// ****************** 検索画面用メソッド **************************************

  /***************************************************************************
   * ユーザー情報を取得するメソッドです。(検索画面用)
   ***************************************************************************
   */
  public void getUserData()
  {
    // ユーザー情報取得 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // トランザクション
                          );

    // 外注出来高情報VO取得
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();
    // 1行めを取得
    OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
    // 従業員区分をセット
    vendorSupplySearchRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // 従業員区分
    // 従業員区分が2:外部の場合、仕入先情報をセット
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      vendorSupplySearchRow.setAttribute("VendorCode", retHashMap.get("VendorCode")); // 取引先コード
      vendorSupplySearchRow.setAttribute("VendorId",   retHashMap.get("VendorId"));   // 取引先ID
      vendorSupplySearchRow.setAttribute("VendorName", retHashMap.get("VendorName")); // 取引先ID
    }
  }

  /***************************************************************************
   * 入力制御を行うメソッドです。(検索画面用)
   ***************************************************************************
   */
  public void readOnlyChanged()
  {
    // 外注出来高情報VO取得
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();
    // 1行めを取得
    OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
    // データ取得
    String peopleCode       = (String)vendorSupplySearchRow.getAttribute("PeopleCode"); // 従業員コード

    // 外注出来高実績:登録PVO取得
    OAViewObject vendorSupplyPvo = getXxpoVendorSupplyPVO1();
    // 1行目を取得
    OARow readOnlyRow = (OARow)vendorSupplyPvo.first();

    // 
    // 従業員コードが1:内部ユーザーの場合
    if (XxpoConstants.PEOPLE_CODE_I.equals(peopleCode)) 
    {
      readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.FALSE); // 取引先入力可

    // 従業員コードが2:外部ユーザーの場合
    } else if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode)) 
    {
      readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.TRUE);  // 取引先入力不可
    }
  }
  
  /***************************************************************************
   * 検索処理を行うメソッドです。(検索画面用)
   * @param searchParams - 検索パラメータ用HashMap
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  )
  {
    // SQLのDATEに変換
    java.sql.Date manufacturedDateFrom =      // 生産日FROM
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("manufacturedDateFrom"));
    java.sql.Date manufacturedDateTo =        // 生産日TO
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("manufacturedDateTo"));
    java.sql.Date productedDateFrom =         // 製造日FROM
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("productedDateFrom"));
    java.sql.Date productedDateTo =           // 製造日TO
      getOADBTransaction().getOANLSServices().stringToDate((String)searchParams.get("productedDateTo"));

    // 外注出来高情報検索VO取得
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();
    // 1行めを取得
    OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
    // 入力項目でない場合、pageContext.getParameter("TxtVendorCode")からでは値を取得できないため、取引先コードはVOから取得する。
    searchParams.put("vendorCode", vendorSupplySearchRow.getAttribute("VendorCode")); // 取引先コード
    
    // 外注出来高情報VO取得
    XxpoVendorSupplyVOImpl xxpoVendorSupplyVo = getXxpoVendorSupplyVO1();
    // 検索
    xxpoVendorSupplyVo.initQuery(
      searchParams,         // 検索パラメータ用HashMap
      manufacturedDateFrom, // 生産日FROM
      manufacturedDateTo,   // 生産日TO
      productedDateFrom,    // 製造日FROM
      productedDateTo);     // 製造日TO
    // 1行目を取得
    OARow row = (OARow)xxpoVendorSupplyVo.first();
  }
  
  /***************************************************************************
   * 初期化処理を行うメソッドです。(検索画面用)
   ***************************************************************************
   */
  public void initialize()
  {
    // *********************************** //
    // * 外注出来高報告:検索VO 空行取得  * //
    // *********************************** //
    OAViewObject vendorSupplySearchVo = getXxpoVendorSupplySearchVO1();

    // 1行もない場合、空行作成
    if (!vendorSupplySearchVo.isPreparedForExecution())
    {
      vendorSupplySearchVo.setMaxFetchSize(0);
      vendorSupplySearchVo.insertRow(vendorSupplySearchVo.createRow());
      // 1行目を取得
      OARow vendorSupplySearchRow = (OARow)vendorSupplySearchVo.first();
      // キーに値をセット
      vendorSupplySearchRow.setNewRowState(Row.STATUS_INITIALIZED);
      vendorSupplySearchRow.setAttribute("RowKey", new Number(1));
    }
    
    // ******************************** //
    // * 外注出来高報告PVO 空行取得   * //
    // ******************************** //
    OAViewObject vendorSupplyPvo = getXxpoVendorSupplyPVO1();   
    // 1行もない場合、空行作成
    if (!vendorSupplyPvo.isPreparedForExecution())
    {    
      vendorSupplyPvo.setMaxFetchSize(0);
      vendorSupplyPvo.insertRow(vendorSupplyPvo.createRow());
      // 1行目を取得
      OARow vendorSupplyPvoRow = (OARow)vendorSupplyPvo.first();
      // キーに値をセット
      vendorSupplyPvoRow.setAttribute("RowKey", new Number(1));
    }
    
    // ******************************* //
    // *     ユーザー情報取得        * //
    // ******************************* //
    getUserData();

    // ******************************* //
    // *      取引先制御設定         * //
    // ******************************* //
    readOnlyChanged();
  }

// ****************** 登録画面用メソッド **************************************

  /***************************************************************************
   * 無効切替制御を行うメソッドです。(登録画面用)
   * @param flag - 0:有効  1:無効
   ***************************************************************************
   */
  public void disabledChanged(
    String flag
  )
  {
    // 外注出来高実績:登録PVO取得
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();    
    // 1行目を取得
    OARow readOnlyRow = (OARow)vendorSupplyMakePvo.first();

    // フラグが0:有効の場合
    if ("0".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled",  Boolean.FALSE); // 適用ボタン押下可
    
    // フラグが1:無効の場合
    } else if ("1".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled",  Boolean.TRUE); // 適用ボタン押下不可

    }
  }
  
  /***************************************************************************
   * 入力制御を行うメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void readOnlyChangedMake()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    String peopleCode         = (String)params.get("PeopleCode");        // 従業員区分
    String processFlag        = (String)params.get("ProcessFlag");       // 処理フラグ
    String productResultType  = (String)params.get("ProductResultType"); // 処理タイプ
    
    // 外注出来高実績:登録PVO取得
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();    
    // 1行目を取得
    OARow readOnlyRow = (OARow)vendorSupplyMakePvo.first();

    // 処理フラグが1:登録の場合
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag))
    {
      readOnlyRow.setAttribute("ManufacturedDateReadOnly",  Boolean.FALSE); // 生産日入力可
      readOnlyRow.setAttribute("FactoryCodeReadOnly",       Boolean.FALSE); // 工場入力可
      readOnlyRow.setAttribute("ItemCodeReadOnly",          Boolean.FALSE); // 品目入力可
      readOnlyRow.setAttribute("ProductedDateReadOnly",     Boolean.FALSE); // 製造日入力可
      readOnlyRow.setAttribute("ProductedQuantityReadOnly", Boolean.FALSE); // 出来高数量入力可
      readOnlyRow.setAttribute("CorrectedQuantityReadOnly", Boolean.TRUE);  // 訂正数量入力不可
      
      // 従業員区分が1:内部ユーザーの場合
      if (XxpoConstants.PEOPLE_CODE_I.equals(peopleCode)) 
      {
        readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.FALSE); // 取引先入力可
    
      // 従業員区分が2:外部ユーザーの場合
      } else if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode)) 
      {
        readOnlyRow.setAttribute("VendorCodeReadOnly", Boolean.TRUE);  // 取引先入力不可
      }
    
    // 処理フラグが2:更新の場合
    } else if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      readOnlyRow.setAttribute("ManufacturedDateReadOnly", Boolean.TRUE); // 生産日入力不可
      readOnlyRow.setAttribute("VendorCodeReadOnly",       Boolean.TRUE); // 取引先入力不可
      readOnlyRow.setAttribute("FactoryCodeReadOnly",      Boolean.TRUE); // 工場入力不可
      readOnlyRow.setAttribute("ItemCodeReadOnly",         Boolean.TRUE); // 品目入力不可
      readOnlyRow.setAttribute("ProductedDateReadOnly",    Boolean.TRUE); // 製造日入力不可

      // 処理タイプが1:相手先在庫の場合
      if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
      {
        readOnlyRow.setAttribute("ProductedQuantityReadOnly", Boolean.FALSE); // 出来高数量入力可
        readOnlyRow.setAttribute("CorrectedQuantityReadOnly", Boolean.TRUE);  // 訂正数量入力不可
      // 処理タイプが2:即時仕入の場合        
      } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
      {
        readOnlyRow.setAttribute("ProductedQuantityReadOnly", Boolean.TRUE);  // 出来高数量入力不可
        readOnlyRow.setAttribute("CorrectedQuantityReadOnly", Boolean.FALSE); // 訂正数量入力可        
      }
    }
  }

  /***************************************************************************
   * 必須制御を行うメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void requiredChanged()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    String itemClassCode   = (String)params.get("ItemClassCode");  // 品目区分
    
    // 外注出来高実績:登録PVO取得
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();    
    // 1行目を取得
    OARow requiredRow = (OARow)vendorSupplyMakePvo.first();

    // 品目区分が5：製品の場合
    if (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode)) 
    {
      requiredRow.setAttribute("ProductedDateRequired", "uiOnly"); // 製造日必須
      
    // その他の場合
    } else
    {
      requiredRow.setAttribute("ProductedDateRequired", "no"); // 製造日必須解除
    }
  }

  /***************************************************************************
   * ユーザー情報を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getUserDataMake()
  {
    // ユーザー情報取得  
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // トランザクション
                          );

    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();   
    // 従業員区分をセット
    vendorSupplyMakeRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // 従業員区分
    // 従業員区分が2:外部の場合、仕入先情報をセット
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      vendorSupplyMakeRow.setAttribute("VendorCode",        retHashMap.get("VendorCode"));        // 取引先コード
      vendorSupplyMakeRow.setAttribute("VendorName",        retHashMap.get("VendorName"));        // 取引先名
      vendorSupplyMakeRow.setAttribute("VendorId",          retHashMap.get("VendorId"));          // 取引先ID
      vendorSupplyMakeRow.setAttribute("ProductResultType", retHashMap.get("ProductResultType")); // 処理タイプ
      vendorSupplyMakeRow.setAttribute("Department",        retHashMap.get("Department"));        // 部署      
    }
  }
  
  /***************************************************************************
   * 賞味期限を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getUseByDate()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    Date productedDate   = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");   // 製造日
    Number itemId        = (Number)vendorSupplyMakeRow.getAttribute("ItemId");        // 品目ID
// 2009-02-06 H.Itou Add Start 本番障害#1147対応
    String itemCode      = (String)vendorSupplyMakeRow.getAttribute("ItemCode");  // 品目コード
// 2009-02-06 H.Itou Add End
    String expirationDay = (String)vendorSupplyMakeRow.getAttribute("ExpirationDay"); // 賞味期間

// 2009-02-06 H.Itou Del Start 本番障害#1147対応
//    // 賞味期間に値がある場合、賞味期限取得
//    if (XxcmnUtility.isBlankOrNull(expirationDay) == false)
//    {
// 2009-02-06 H.Itou Del End
      Date useByDate = XxpoUtility.getUseByDate(
                         getOADBTransaction(), // トランザクション
                         itemId,               // 品目ID
                         productedDate,        // 製造日
// 2009-02-06 H.Itou Add Start 本番障害#1147対応
//                         expirationDay         // 賞味期間
                         itemCode              // 品目コード
// 2009-02-06 H.Itou Add End
                       );
      // 賞味期限を外注出来高情報:登録VOにセット
      vendorSupplyMakeRow.setAttribute("UseByDate", useByDate);
// 2009-02-06 H.Itou Del Start 本番障害#1147対応    
//    // 賞味期間に値がない場合、NULL
//    } else
//    {
//      // 賞味期限を外注出来高情報:登録VOにセット
//      vendorSupplyMakeRow.setAttribute("UseByDate", "");      
//    }
// 2009-02-06 H.Itou Del End
  }

  /***************************************************************************
   * 固有記号を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getKoyuCode()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得        
    Number itemId         = (Number)vendorSupplyMakeRow.getAttribute("ItemId");         // 品目ID
    Number factoryId      = (Number)vendorSupplyMakeRow.getAttribute("FactoryId");      // 工場ID
    Date manufacturedDate = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate"); // 生産日
// 2009-02-18 H.Itou Add Start 本番障害#1178
    Date productedDate    = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");    // 製造日
    String unitPriceCalcCode = (String)vendorSupplyMakeRow.getAttribute("UnitPriceCalcCode");// 仕入単価導出日タイプ
    Date standardDate; // 基準日

    // 仕入単価導入日タイプが1:製造日の場合
    if ("1".equals(unitPriceCalcCode))
    {
      // 基準日は製造日
      standardDate = productedDate;

    // 仕入単価導入日タイプが2:生産日の場合
    } else
    {
      // 基準日は生産日
      standardDate = manufacturedDate;
    }
// 2009-02-18 H.Itou Add End
        
    // 固有記号取得
    String koyuCode = XxpoUtility.getKoyuCode(
                        getOADBTransaction(), // トランザクション
                        itemId,            // 品目ID
                        factoryId,         // 工場ID
// 2009-02-18 H.Itou Add Start 本番障害#1178
//                        manufacturedDate   // 生産日
                        standardDate       // 基準日
// 2009-02-18 H.Itou Add End
                      );
    
    vendorSupplyMakeRow.setAttribute("KoyuCode", koyuCode);
  }

  /***************************************************************************
   * 製造日を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getProductedDate()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得        
    Date manufacturedDate = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate"); // 生産日
    Date productedDate    = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");    // 製造日

    // 製造日がNullの場合、生産日をセット
    if (XxcmnUtility.isBlankOrNull(productedDate))
    {
      vendorSupplyMakeRow.setAttribute("ProductedDate", manufacturedDate); // 製造日
    }
  }

// 2015-10-06 S.Yamashita Add Start
  /***************************************************************************
   * ロット情報を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getLotMst()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行目を取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    String itemClassCode = (String)vendorSupplyMakeRow.getAttribute("ItemClassCode");// 品目区分
    Number itemId        = (Number)vendorSupplyMakeRow.getAttribute("ItemId");       // 品目ID
    Date productedDate   = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");  // 製造日
    String koyuCode      = (String)vendorSupplyMakeRow.getAttribute("KoyuCode");     // 固有記号
    
    // 品目区分が5：製品の場合
    if (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
    {
      // ロット情報取得
      HashMap retHashMap = XxpoUtility.getLotMst(
                    getOADBTransaction(), // トランザクション
                    itemId,               // 品目ID
                    productedDate,        // 製造日
                    koyuCode              // 固有記号
                  );
      // 外注出来高情報:登録VOにセット
      vendorSupplyMakeRow.setAttribute("LotNumber"      , retHashMap.get("LotNumber"));      // ロットNo
      vendorSupplyMakeRow.setAttribute("LotId"          , retHashMap.get("LotId"));          // ロットID
      vendorSupplyMakeRow.setAttribute("LotStatus"      , retHashMap.get("LotStatus"));      // ロットステータス
      vendorSupplyMakeRow.setAttribute("QtInspectReqNo" , retHashMap.get("QtInspectReqNo")); // 品質検査依頼No
    }else
    {
      // 品目区分が「5:製品」以外の場合はNULLをセット
      // 外注出来高情報:登録VOにセット
      vendorSupplyMakeRow.setAttribute("LotNumber"      , ""); // ロットNo
      vendorSupplyMakeRow.setAttribute("LotId"          , ""); // ロットID
      vendorSupplyMakeRow.setAttribute("LotStatus"      , ""); // ロットステータス
      vendorSupplyMakeRow.setAttribute("QtInspectReqNo" , ""); // 品質検査依頼No
    }
  }
// 2015-10-06 S.Yamashita Add End
  /***************************************************************************
   * 入力チェックを行うメソッドです。(登録画面用)
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void messageTextCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    Object manufacturedDate  = vendorSupplyMakeRow.getAttribute("ManufacturedDate");      // 生産日
    Object vendorCode        = vendorSupplyMakeRow.getAttribute("VendorCode");            // 取引先
    Object factoryCode       = vendorSupplyMakeRow.getAttribute("FactoryCode");           // 工場コード
    Object itemCode          = vendorSupplyMakeRow.getAttribute("ItemCode");              // 品目コード
    Object productedDate     = vendorSupplyMakeRow.getAttribute("ProductedDate");         // 製造日
    Object koyuCode          = vendorSupplyMakeRow.getAttribute("KoyuCode");              // 固有記号
    Object productedQuantity = vendorSupplyMakeRow.getAttribute("ProductedQuantity");     // 数量
    Object productedUom      = vendorSupplyMakeRow.getAttribute("ProductedUom");          // 数量(単位コード)
    Object correctedQuantity = vendorSupplyMakeRow.getAttribute("CorrectedQuantity");     // 訂正数量
    Object itemClassCode     = vendorSupplyMakeRow.getAttribute("ItemClassCode");         // 品目区分
    String costManageCode    = (String)vendorSupplyMakeRow.getAttribute("CostManageCode");// 原価管理区分
// 2008-07-11 D.Nihei ADD START
    String productResultType = (String)vendorSupplyMakeRow.getAttribute("ProductResultType");// 処理タイプ
    String processFlag       = (String)vendorSupplyMakeRow.getAttribute("ProcessFlag");      // 処理フラグ
    // システム日付を取得
    Date currentDate = getOADBTransaction().getCurrentDBDate();
// 2008-07-11 D.Nihei ADD END
// 2008-07-22 H.Itou  ADD START
    Number conversionFactor = (Number)vendorSupplyMakeRow.getAttribute("ConversionFactor"); // 換算入数
// 2008-07-22 H.Itou  ADD END
    
    // 生産日必須チェック
    if (XxcmnUtility.isBlankOrNull(manufacturedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ManufacturedDate",
                            manufacturedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
// 2008-07-11 D.Nihei ADD START
    // 処理タイプが「1：相手先在庫管理」で且つ、生産日が未来日の場合
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)
            && XxcmnUtility.chkCompareDate(1, (Date)manufacturedDate, currentDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ManufacturedDate",
                            manufacturedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
// 2008-07-11 D.Nihei ADD END
    }
    
    // 取引先必須チェック
    if (XxcmnUtility.isBlankOrNull(vendorCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "VendorCode",
                            vendorCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
    }
    
    // 工場コード必須チェック
    if (XxcmnUtility.isBlankOrNull(factoryCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "FactoryCode",
                            factoryCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
    }
    
    // 品目必須チェック
    if (XxcmnUtility.isBlankOrNull(itemCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ItemCode",
                            itemCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
                            
// 2008-07-22 H.Itou  ADD START
    // 品目のケース入数チェック NULLか0以下はエラー
    } else if (XxcmnUtility.isBlankOrNull(conversionFactor)
      || (XxcmnUtility.intValue(conversionFactor) <= 0))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ItemCode",
                            itemCode,
                            XxcmnConstants.APPL_XXCMN,         
                            XxcmnConstants.XXCMN10603));
    }
// 2008-07-22 H.Itou  ADD END

    // 品目区分が5：製品の場合、製造日、固有記号必須
    if (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode)) 
    {
      // 製造日必須チェック
      if (XxcmnUtility.isBlankOrNull(productedDate)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedDate",
                              productedDate,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10002));
      }
      
      // 固有記号必須チェック
      if (XxcmnUtility.isBlankOrNull(koyuCode)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "KoyuCode",
                              koyuCode,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10002));
      }
    }

    // 数量必須チェック
    if (XxcmnUtility.isBlankOrNull(productedQuantity)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ProductedQuantity",
                            productedQuantity,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
                            
    // 入力がある場合は数値チェック
    } else
    {
      // 数値でない場合はエラー
      if (!XxcmnUtility.chkNumeric(productedQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedQuantity",
                              productedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

// 2008-07-11 D.Nihei ADD START
      // 新規の場合は、数量0をエラーとする
      } else if(XxpoConstants.PROCESS_FLAG_I.equals(processFlag) 
            &&  XxcmnUtility.chkCompareNumeric(2, XxcmnConstants.STRING_ZERO, productedQuantity))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedQuantity",
                              productedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10227));
// 2008-07-11 D.Nihei ADD END
// 2008-07-11 D.Nihei MOD START
//      // マイナス値はエラー
//      } else if(!XxcmnUtility.chkCompareNumeric(2, productedQuantity, "0"))
      // 更新の場合は、マイナス値をエラーとする
      } else if(XxpoConstants.PROCESS_FLAG_U.equals(processFlag) 
            &&  XxcmnUtility.chkCompareNumeric(1, XxcmnConstants.STRING_ZERO, productedQuantity))
// 2008-07-11 D.Nihei MOD END
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "ProductedQuantity",
                              productedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
      }
    }
    
    // 数量(単位コード)必須チェック
    if (XxcmnUtility.isBlankOrNull(productedUom)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ProductedUom",
                            productedUom,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));
    }

    // 訂正数値チェック
    // 入力ありの場合のみ
    if (XxcmnUtility.isBlankOrNull(correctedQuantity) == false)
    {
      // 数値でない場合はエラー
      if (!XxcmnUtility.chkNumeric(correctedQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "CorrectedQuantity",
                              correctedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

      // マイナス値はエラー
      } else if(!XxcmnUtility.chkCompareNumeric(2, correctedQuantity, "0"))
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vendorSupplyMakeVo.getName(),
                              vendorSupplyMakeRow.getKey(),
                              "CorrectedQuantity",
                              correctedQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
      }
    }
  }

  /***************************************************************************
   * 処理タイプチェックを行うメソッドです。(登録画面用)
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void productResultTypeCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    Object productResultType  = vendorSupplyMakeRow.getAttribute("ProductResultType"); // 処理タイプ
    Object vendorCode         = vendorSupplyMakeRow.getAttribute("VendorCode");        // 取引先

    // 処理タイプ0:生産実績なし の場合、エラー
    if (XxpoConstants.PRODUCT_RESULT_TYPE_M.equals(productResultType))
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_ENTRY);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_DATA,  XxpoConstants.TOKEN_NAME_DATA);
      
      // エラーメッセージ取得
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "VendorCode",
                            vendorCode,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10003,
                            tokens));
    }
  }

// 2008-10-23 H.Itou Add Start
  /***************************************************************************
   * 倉庫管理元チェックを行うメソッドです。
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void customerStockWhseCheck() throws OAException 
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    Object productResultType  = vendorSupplyMakeRow.getAttribute("ProductResultType"); // 処理タイプ
    Object customerStockWhse  = vendorSupplyMakeRow.getAttribute("CustomerStockWhse"); // 相手先在庫管理対象
    Object factoryCode        = vendorSupplyMakeRow.getAttribute("FactoryCode");       // 工場コード

    // 相手先在庫管理対象フラグがNULLの場合エラー
    if (XxcmnUtility.isBlankOrNull(customerStockWhse))
    {
      // エラーメッセージ取得
      throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10274);
    
    // 処理タイプ1:相手先在庫で、相手先在庫管理対象フラグが1：相手先在庫管理倉庫でない場合、エラー
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)
             && !XxpoConstants.CUSTOMER_STOCK_WHSE_AITE.equals(customerStockWhse))
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = {new MessageToken(XxpoConstants.TOKEN_VALUE, XxpoConstants.TOKEN_CUSTOMER_STOCK_WHSE_AITE)};
        
      // エラーメッセージ取得
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                             XxpoConstants.XXPO10275,
                             tokens);

    // 処理タイプ2:即時仕入で、相手先在庫管理対象フラグが0：伊藤園在庫管理倉庫でない場合、エラー
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType)
             && !XxpoConstants.CUSTOMER_STOCK_WHSE_ITOEN.equals(customerStockWhse))
    {
      // エラーメッセージトークン取得
      MessageToken[] tokens = {new MessageToken(XxpoConstants.TOKEN_VALUE, XxpoConstants.TOKEN_CUSTOMER_STOCK_WHSE_ITOEN)};
      
      // エラーメッセージ取得
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10275,
                              tokens);
    }
  }
// 2008-10-23 H.Itou Add End
  /***************************************************************************
   * 在庫クローズチェックを行うメソッドです。(登録画面用)
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void stockCloseCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    Date manufacturedDate  = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate"); // 生産日
    
    // 在庫クローズチェック
    if (XxpoUtility.chkStockClose(
          getOADBTransaction(), // トランザクション
          manufacturedDate)     // 生産日
        ) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            "ManufacturedDate",
                            manufacturedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10004));
    }    
  }
  /***************************************************************************
   * ロット存在確認チェックを行うメソッドです。(登録画面用)
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void lotCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    Number itemId        = (Number)vendorSupplyMakeRow.getAttribute("ItemId");      // 品目ID
    Date   productedDate = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate"); // 製造日
    String koyuCode      = (String)vendorSupplyMakeRow.getAttribute("KoyuCode");    // 固有記号

    // ロット存在確認チェック
    if (XxpoUtility.chkLotMst(
          getOADBTransaction(), // トランザクション
          itemId,               // 品目ID
          productedDate,        // 製造日 
          koyuCode              // 固有記号
          )
        ) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vendorSupplyMakeVo.getName(),
                            vendorSupplyMakeRow.getKey(),
                            null,
                            null,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10005));
    }    
  }

  /***************************************************************************
   * 引当可能数量チェックを行うメソッドです。(登録画面用)
   * @param exceptions - エラーリスト
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public HashMap reservedQuantityCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    String productedQuantity = (String)vendorSupplyMakeRow.getAttribute("ProductedQuantity");// 数量
    Number txnsId            = (Number)vendorSupplyMakeRow.getAttribute("TxnsId");           // 実績ID

    // 引当可能数チェック
    HashMap paramsRet = XxpoUtility.chkReservedQuantity(
                          getOADBTransaction(), // トランザクション
                          productedQuantity,    // 出来高数量
                          txnsId                // 実績ID
                          );
    return paramsRet;
  }

  /***************************************************************************
   * 在庫単価を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getStockValue()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データを取得
    String costManageCode    = (String)vendorSupplyMakeRow.getAttribute("CostManageCode");   // 原価管理区分
    String productResultType = (String)vendorSupplyMakeRow.getAttribute("ProductResultType");// 処理タイプ
    String unitPriceCalcCode = (String)vendorSupplyMakeRow.getAttribute("UnitPriceCalcCode");// 仕入単価導出日タイプ
    Number itemId            = (Number)vendorSupplyMakeRow.getAttribute("ItemId");           // 品目ID
    Number vendorId          = (Number)vendorSupplyMakeRow.getAttribute("VendorId");         // 取引先ID
    Number factoryId         = (Number)vendorSupplyMakeRow.getAttribute("FactoryId");        // 工場ID
    Date manufacturedDate    = (Date)vendorSupplyMakeRow.getAttribute("ManufacturedDate");   // 生産日
    Date productedDate       = (Date)vendorSupplyMakeRow.getAttribute("ProductedDate");      // 製造日

    // パラメータ作成
    HashMap params = new HashMap();
    params.put("CostManageCode",    costManageCode);   // 原価管理区分
    params.put("ProductResultType", productResultType);// 処理タイプ
    params.put("UnitPriceCalcCode", unitPriceCalcCode);// 仕入単価導出日タイプ
    params.put("ItemId",            itemId);           // 品目ID
    params.put("VendorId",          vendorId);         // 取引先ID
    params.put("FactoryId",         factoryId);        // 工場ID
    params.put("ManufacturedDate",  manufacturedDate); // 生産日
    params.put("ProductedDate",     productedDate);    // 製造日
    // 在庫単価取得実行
    String stockValue = XxpoUtility.getStockValue(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );

    vendorSupplyMakeRow.setAttribute("StockValue", stockValue);
  }

  /***************************************************************************
   * 発注番号を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getPoNumber()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();

    // 発注番号取得実行
    String poNumber = XxpoUtility.getPoNumber(
                          getOADBTransaction() // トランザクション
                          );

    vendorSupplyMakeRow.setAttribute("PoNumber", poNumber);
  }

  /***************************************************************************
   * 納入先情報を取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getLocationData()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // データ取得
    String productResultType = (String)vendorSupplyMakeRow.getAttribute("ProductResultType");// 処理タイプ
    String vendorStockWhse   = (String)vendorSupplyMakeRow.getAttribute("VendorStockWhse");  // 相手先在庫入庫先
    String deliveryWhse      = (String)vendorSupplyMakeRow.getAttribute("DeliveryWhse");     // 発注納入先
    String locationCode      = null;

    // 処理タイプ1:相手先在庫の場合、
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
    {
      // 相手先在庫入庫先から納入先情報を取得
      locationCode = vendorStockWhse;

    // 処理タイプ2:即時仕入の場合、
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      // 発注納入先から納入先情報を取得
      locationCode = deliveryWhse;
      
    }
      // 相手先在庫入庫先から納入先情報を取得
      HashMap retHashMap = XxpoUtility.getLocationData(
                            getOADBTransaction(),  // トランザクション
                            locationCode           // 納入先
                            );

      vendorSupplyMakeRow.setAttribute("LocationId",       retHashMap.get("LocationId"));       // 納入先ID
      vendorSupplyMakeRow.setAttribute("WhseCode",         retHashMap.get("WhseCode"));         // 倉庫コード
      vendorSupplyMakeRow.setAttribute("LocationCode",     locationCode);                       // 納入先コード
      vendorSupplyMakeRow.setAttribute("CoCode",           retHashMap.get("CoCode"));           // 会社コード
      vendorSupplyMakeRow.setAttribute("OrgnCode",         retHashMap.get("OrgnCode"));         // 組織コード
      vendorSupplyMakeRow.setAttribute("ShipToLocationId", retHashMap.get("ShipToLocationId")); // 納入先事業所ID
      vendorSupplyMakeRow.setAttribute("OrganizationId",   retHashMap.get("OrganizationId"));   // 在庫組織ID
// 2008-10-23 H.Itou Add Start 相手先在庫管理対象を追加
      vendorSupplyMakeRow.setAttribute("CustomerStockWhse", retHashMap.get("CustomerStockWhse"));   // 相手先在庫管理対象
// 2008-10-23 H.Itou Add End
  }

  /***************************************************************************
   * 検査依頼Noを取得するメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void getQtInspectReqNo()
  {   
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();

    // 発注番号取得実行
    Object qtInspectReqNo = XxpoUtility.getQtInspectReqNo(
                          getOADBTransaction(), // トランザクション
                          params
                          );
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first(); 

    vendorSupplyMakeRow.setAttribute("QtInspectReqNo", qtInspectReqNo);
  }
  
  /***************************************************************************
   * 外注出来高VOをHashMapに格納するメソッドです。(登録画面用)
   * @return HashMap - 外注出来高VO HashMap
   ***************************************************************************
   */
  public HashMap getAllDataHashMap()
  {
    HashMap params = new HashMap();

    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();        
        
    // 仕入先関連データ
    params.put("VendorId",          vendorSupplyMakeRow.getAttribute("VendorId"));          // 取引先ID
    params.put("VendorCode",        vendorSupplyMakeRow.getAttribute("VendorCode"));        // 取引先
    params.put("VendorName",        vendorSupplyMakeRow.getAttribute("VendorName"));        // 取引先名
    params.put("ProductResultType", vendorSupplyMakeRow.getAttribute("ProductResultType")); // 処理タイプ
    params.put("Department",        vendorSupplyMakeRow.getAttribute("Department"));        // 部署
    // 仕入先サイト関連データ
    params.put("FactoryId",         vendorSupplyMakeRow.getAttribute("FactoryId"));         // 工場ID
    params.put("FactoryCode",       vendorSupplyMakeRow.getAttribute("FactoryCode"));       // 工場コード
    params.put("FactoryName",       vendorSupplyMakeRow.getAttribute("FactoryName"));       // 工場名
    params.put("VendorStockWhse",   vendorSupplyMakeRow.getAttribute("VendorStockWhse"));   // 相手先在庫入庫先
    params.put("DeliveryWhse",      vendorSupplyMakeRow.getAttribute("DeliveryWhse"));      // 発注納入先
    // 品目関連データ
    params.put("ItemId",            vendorSupplyMakeRow.getAttribute("ItemId"));            // 品目ID
    params.put("ItemCode",          vendorSupplyMakeRow.getAttribute("ItemCode"));          // 品目コード
    params.put("ItemName",          vendorSupplyMakeRow.getAttribute("ItemName"));          // 品目名
    params.put("CostManageCode",    vendorSupplyMakeRow.getAttribute("CostManageCode"));    // 原価管理区分
    params.put("TestCode",          vendorSupplyMakeRow.getAttribute("TestCode"));          // 試験有無区分
    params.put("LotStatus",         vendorSupplyMakeRow.getAttribute("LotStatus"));         // ロットステータス
    if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(params.get("ProductResultType")))    // 処理タイプが2:即時仕入の場合
    {
      params.put("StockQty",        vendorSupplyMakeRow.getAttribute("StockQty"));          // 在庫入数     
    } 
    params.put("Uom",               vendorSupplyMakeRow.getAttribute("Uom"));               // 数量(単位コード)
    params.put("ProductedUom",      vendorSupplyMakeRow.getAttribute("ProductedUom"));      // 出来高数量(単位コード)
    params.put("ConversionFactor",  vendorSupplyMakeRow.getAttribute("ConversionFactor"));  // 換算入数
    params.put("ExpirationDay",     vendorSupplyMakeRow.getAttribute("ExpirationDay"));     // 賞味期間
    params.put("UnitPriceCalcCode", vendorSupplyMakeRow.getAttribute("UnitPriceCalcCode")); // 仕入単価導出日タイプ
    params.put("InventoryItemId",   vendorSupplyMakeRow.getAttribute("InventoryItemId"));   // INV品目ID
    params.put("ItemClassCode",     vendorSupplyMakeRow.getAttribute("ItemClassCode"));     // 品目区分
    // 画面から取得したデータ
    params.put("TxnsId",            vendorSupplyMakeRow.getAttribute("TxnsId"));            // 実績ID
    params.put("ManufacturedDate",  vendorSupplyMakeRow.getAttribute("ManufacturedDate"));  // 生産日
    params.put("ProductedDate",     vendorSupplyMakeRow.getAttribute("ProductedDate"));     // 製造日
    params.put("KoyuCode",          vendorSupplyMakeRow.getAttribute("KoyuCode"));          // 固有記号
    params.put("UseByDate",         vendorSupplyMakeRow.getAttribute("UseByDate"));         // 賞味期限
    params.put("Quantity",          vendorSupplyMakeRow.getAttribute("Quantity"));          // 数量
    params.put("ProductedQuantity", vendorSupplyMakeRow.getAttribute("ProductedQuantity")); // 出来高数量
    params.put("CorrectedQuantity", vendorSupplyMakeRow.getAttribute("CorrectedQuantity")); // 訂正数量
    params.put("Description",       vendorSupplyMakeRow.getAttribute("Description"));       // 備考
    params.put("LastUpdateDate",    vendorSupplyMakeRow.getAttribute("LastUpdateDate"));    // 最終更新日
    // 発注番号取得(getPoNumber)で取得したデータ
    params.put("PoNumber",          vendorSupplyMakeRow.getAttribute("PoNumber"));          // 発注番号
    // 在庫単価取得(getStockValue)で取得したデータ
    params.put("StockValue",        vendorSupplyMakeRow.getAttribute("StockValue"));        // 在庫単価
    // ロットマスタ登録処理(insertLotMst)で取得したデータ
    params.put("LotNumber",         vendorSupplyMakeRow.getAttribute("LotNumber"));         // ロット番号
    params.put("LotId",             vendorSupplyMakeRow.getAttribute("LotId"));             // ロットID    
// 2009-02-18 H.Itou Add Start 本番障害#1096
    params.put("CreateLotDiv",      vendorSupplyMakeRow.getAttribute("CreateLotDiv"));      // 作成区分
// 2009-02-18 H.Itou Add End
    // 納入先情報取得(getLocationData)で取得したデータ
    params.put("LocationId",        vendorSupplyMakeRow.getAttribute("LocationId"));        // 納入先ID
    params.put("LocationCode",      vendorSupplyMakeRow.getAttribute("LocationCode"));      // 納入先コード
    params.put("WhseCode",          vendorSupplyMakeRow.getAttribute("WhseCode"));          // 倉庫コード    
    params.put("CoCode",            vendorSupplyMakeRow.getAttribute("CoCode"));            // 会社コード
    params.put("OrgnCode",          vendorSupplyMakeRow.getAttribute("OrgnCode"));          // 組織コード
    params.put("ShipToLocationId",  vendorSupplyMakeRow.getAttribute("ShipToLocationId"));  // 納入先事業所ID
    params.put("OrganizationId",    vendorSupplyMakeRow.getAttribute("OrganizationId"));    // 在庫組織ID
// 2008-10-23 H.Itou Add Start 相手先在庫管理対象を追加
    params.put("CustomerStockWhse", vendorSupplyMakeRow.getAttribute("CustomerStockWhse")); // 相手先在庫管理対象
// 2008-10-23 H.Itou Add End
      
    // 処理フラグ1:登録 2:更新
    params.put("ProcessFlag",       vendorSupplyMakeRow.getAttribute("ProcessFlag"));
    // 従業員区分1:内部 2:外部
    params.put("PeopleCode",       vendorSupplyMakeRow.getAttribute("PeopleCode"));

    // 品質検査依頼情報作成・更新に使用するデータ
    // 処理タイプが1:相手先在庫の場合
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(params.get("ProductResultType")))
    {
      params.put("Division",        "4"); // 区分 4:外注出来高

    // 処理タイプが2:即時仕入の場合
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(params.get("ProductResultType"))) 
    {
      params.put("Division",        "2"); // 区分 2:発注
    }
    params.put("QtInspectReqNo",    vendorSupplyMakeRow.getAttribute("QtInspectReqNo")); // 検査依頼No

    return params;
    
  }
 
  /***************************************************************************
   * ロットマスタ登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insLotMst()
  {

    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // 値を取得
    Number itemId    = (Number)vendorSupplyMakeRow.getAttribute("ItemId");    // 品目ID
    String itemCode  = (String)vendorSupplyMakeRow.getAttribute("ItemCode");  // 品目コード
    String lotStatus = (String)vendorSupplyMakeRow.getAttribute("LotStatus"); // 品目ID
    
    // ロット番号取得
    String lotNumber = XxpoUtility.getLotNumber(
                         getOADBTransaction(), // トランザクション
                         itemId,               // 品目ID
                         itemCode              // 品目コード
                         );
                         
    vendorSupplyMakeRow.setAttribute("LotNumber", lotNumber);


    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    // ロット作成API 実行
    HashMap retHashMap = XxpoUtility.insertLotMst(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
    // ロットID取得                      
    vendorSupplyMakeRow.setAttribute("LotId", retHashMap.get("LotId"));
    
    return (String)retHashMap.get("RetFlag");
  }

  /***************************************************************************
   * 完了在庫トランザクション登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insInventoryPosting()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertInventoryPosting(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * ロット原価登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insLotCost()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertLotCostAdjustment(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * 外注出来高実績登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insXxpoVendorSupplyTxns()
  {

    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();

    // 外注出来高実績登録 実行
    HashMap retHashMap = XxpoUtility.insertXxpoVendorSupplyTxns(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // 実績IDセット
    vendorSupplyMakeRow.setAttribute("TxnsId", retHashMap.get("TxnsId"));
    
    return (String)retHashMap.get("RetFlag");
  }

  /***************************************************************************
   * 発注ヘッダ(アドオン)登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insXxpoHeadersAll()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertXxpoHeadersAll(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * 発注ヘッダオープンIF登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insPoHeadersIf()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertPoHeadersIf(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * 発注明細オープンIF登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insPoLinesIf()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertPoLinesIf(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * 搬送明細オープンIF登録処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insPoDistributionsIf()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.insertPoDistributionsIf(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * 品質検査依頼情報実行処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String doQtInspection()
  {
    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();
    
    return XxpoUtility.doQtInspection(
                          getOADBTransaction(), // トランザクション
                          params                // パラメータ
                          );
  }

  /***************************************************************************
   * 外注出来高実績更新処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String updXxpoVendorSupplyTxns()
  {

    // 外注出来高VOデータ取得
    HashMap params = getAllDataHashMap();

    // 外注出来高実績登録 実行
    return XxpoUtility.updateXxpoVendorSupplyTxns(
              getOADBTransaction(), // トランザクション
              params                // パラメータ
              );
  }

  /***************************************************************************
   * VOの初期化処理を行うメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void initializeMake()
  {
    // ************************************* //
    // * 外注出来高報告:登録VO 空行取得    * //
    // ************************************* //
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行もない場合、空行作成
    if (!vendorSupplyMakeVo.isPreparedForExecution())
    {
      vendorSupplyMakeVo.setWhereClauseParam(0,null);
      vendorSupplyMakeVo.executeQuery();
      vendorSupplyMakeVo.insertRow(vendorSupplyMakeVo.createRow());
      // 1行目を取得
      OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
      // キーに値をセット
      vendorSupplyMakeRow.setNewRowState(Row.STATUS_INITIALIZED);
      vendorSupplyMakeRow.setAttribute("TxnsId", new Number(-1));
    }
    
    // ************************************* //
    // * 外注出来高報告:登録PVO 空行取得   * //
    // ************************************* //
    OAViewObject vendorSupplyMakePvo = getXxpoVendorSupplyMakePVO1();   
    // 1行もない場合、空行作成
    if (!vendorSupplyMakePvo.isPreparedForExecution())
    {    
      // 1行もない場合、空行作成
      vendorSupplyMakePvo.setMaxFetchSize(0);
      vendorSupplyMakePvo.executeQuery();
      vendorSupplyMakePvo.insertRow(vendorSupplyMakePvo.createRow());
      // 1行目を取得
      OARow vendorSupplyMakePvoRow = (OARow)vendorSupplyMakePvo.first();
      // キーに値をセット
      vendorSupplyMakePvoRow.setAttribute("RowKey", new Number(1));
    }    
  }

  /***************************************************************************
   * 検索処理を行うメソッドです。(登録画面用)
   * @param searchTxnsId - 検索パラメータ実績ID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doSearch(String searchTxnsId) throws OAException
  {
    // 外注出来高情報:登録VO取得
    XxpoVendorSupplyMakeVOImpl vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 検索
    vendorSupplyMakeVo.initQuery(searchTxnsId);         // 検索パラメータ実績ID
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();

    // データを取得できなかった場合
    if (vendorSupplyMakeVo.getRowCount() == 0)
    {
      // *********************** //
      // *  VO初期化処理       * //
      // *********************** //
      OAViewObject vo = getXxpoVendorSupplyMakeVO1();
      vo.setWhereClauseParam(0,null);
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      // 1行目を取得
      OARow row = (OARow)vo.first();
      // キーに値をセット
      row.setNewRowState(Row.STATUS_INITIALIZED);
      row.setAttribute("TxnsId", new Number(-1));
      
      // *********************** //
      // *  無効切替処理       * //
      // *********************** //
      disabledChanged("1"); // 無効に設定

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
    
    // データを取得できた場合
    else 
    {
      // 処理フラグ2:更新をセット
      vendorSupplyMakeRow.setAttribute("ProcessFlag", XxpoConstants.PROCESS_FLAG_U);
      
      // *********************** //
      // *  無効切替処理       * //
      // *********************** //
      disabledChanged("0"); // 有効に設定
        
      // *********************** //
      // *  入力制御処理       *
      // *********************** //
      readOnlyChangedMake();      

      // *********************** //
      // *  必須切替処理       * //
      // *********************** //
      requiredChanged();
    }
  }

  /***************************************************************************
   * 新規行挿入処理を行うメソッドです。(登録画面用)
   ***************************************************************************
   */
  public void addRow()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo  = getXxpoVendorSupplyMakeVO1();
    // 1行目を取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // 処理フラグ1:登録をセット
    vendorSupplyMakeRow.setAttribute("ProcessFlag", XxpoConstants.PROCESS_FLAG_I); // 処理フラグ 1:登録

    // *********************** //
    // * ユーザー情報取得    * //
    // *********************** //
    getUserDataMake();

    // *********************** //
    // *  無効切替処理       * //
    // *********************** //
    disabledChanged("0"); // 有効に設定
        
    // *********************** //
    // *  入力制御処理       *
    // *********************** //
    readOnlyChangedMake();      

    // *********************** //
    // *  必須切替処理       * //
    // *********************** //
    requiredChanged();

  }

  /***************************************************************************
   * 取引先変更時処理です。(登録画面用)
   ***************************************************************************
   */
  public void vendorCodeChanged()
  {
    // 外注出来高情報:登録VO取得
    OAViewObject vendorSupplyMakeVo = getXxpoVendorSupplyMakeVO1();
    // 1行めを取得
    OARow vendorSupplyMakeRow = (OARow)vendorSupplyMakeVo.first();
    // 工場データをリセット
    vendorSupplyMakeRow.setAttribute("FactoryCode",     ""); // 工場コード
    vendorSupplyMakeRow.setAttribute("FactoryName",     ""); // 工場名
    vendorSupplyMakeRow.setAttribute("FactoryId",       ""); // 工場ID
    vendorSupplyMakeRow.setAttribute("DeliveryWhse",    ""); // 発注納入先
    vendorSupplyMakeRow.setAttribute("VendorStockWhse", ""); // 相手先在庫入庫先
    // 工場データから取得する項目をリセット
    vendorSupplyMakeRow.setAttribute("KoyuCode",        ""); // 固有記号
// 2015-10-06 S.Yamashita Add Start
    vendorSupplyMakeRow.setAttribute("LotNumber",       ""); // ロットNo
    vendorSupplyMakeRow.setAttribute("LotId",           ""); // ロットID
    vendorSupplyMakeRow.setAttribute("LotStatus",       ""); // ロットステータス
    vendorSupplyMakeRow.setAttribute("QtInspectReqNo",  ""); // 品質検査依頼No
// 2015-10-06 S.Yamashita Add End

    // 入力制御
    readOnlyChangedMake();
  }

  /***************************************************************************
   * 工場変更時処理です。(登録画面用)
   ***************************************************************************
   */
  public void factoryCodeChanged()
  {
    // 固有記号取得
    getKoyuCode(); 
// 2015-10-06 S.Yamashita Add Start
    // ロット情報取得
    getLotMst();
// 2015-10-06 S.Yamashita Add End
  }

  /***************************************************************************
   * 品目変更時処理です。(登録画面用)
   ***************************************************************************
   */
  public void itemCodeChanged()
  {
    // 必須入力切替
    requiredChanged();
        
    // 固有記号取得
    getKoyuCode(); 
        
    // 賞味期限取得
    getUseByDate(); 
// 2015-10-06 S.Yamashita Add Start
    // ロット情報取得
    getLotMst();
// 2015-10-06 S.Yamashita Add End
  }

  /***************************************************************************
   * 生産日変更時処理です。(登録画面用)
   ***************************************************************************
   */
  public void manufacturedDateChanged()
  {        
    // 固有記号取得
    getKoyuCode();

    // 製造日取得
    getProductedDate();
    
    // 賞味期限取得
    getUseByDate();
// 2015-10-06 S.Yamashita Add Start
    // ロット情報取得
    getLotMst();
// 2015-10-06 S.Yamashita Add End
  }

  /***************************************************************************
   * 製造日変更時処理です。(登録画面用)
   ***************************************************************************
   */
  public void productedDateChanged()
  {
// 2009-02-18 H.Itou Add Start 本番障害#1178
    // 固有記号取得
    getKoyuCode(); 
// 2009-02-18 H.Itou Add End

    // 賞味期限取得
    getUseByDate();
// 2015-10-06 S.Yamashita Add Start
    // ロット情報取得
    getLotMst();
// 2015-10-06 S.Yamashita Add End
  }

  /***************************************************************************
   * 登録・更新時のチェックを行います。(登録画面用)
   * @return HashMap - リターンコード、警告メッセージ
   ***************************************************************************
   */
  public HashMap allCheck()
  {
    // OA例外リストを生成します。
    ArrayList exceptions = new ArrayList(100);
    HashMap paramsRet = new HashMap();
    
    // 外注出来高情報取得
    HashMap params = getAllDataHashMap();
    String costManageCode = (String)params.get("CostManageCode"); // 原価管理区分
    Object processFlag    = (Object)params.get("ProcessFlag");    // 処理フラグ
    Object itemClassCode  = (Object)params.get("ItemClassCode");  // 品目区分

// 2009-02-06 H.Itou Add Start 本番障害#1147対応 カーソル移動しないで適用ボタンを押した場合を想定。
    // 固有記号に値がない場合、自動算出
    if (XxcmnUtility.isBlankOrNull(params.get("koyuCode")))
    {
      // ************************** //
      // *   固有記号算出         * //
      // ************************** //
      getKoyuCode();
    }
    // 賞味期限に値がない場合、自動算出
    if (XxcmnUtility.isBlankOrNull(params.get("useByDate")))
    {
      // ************************** //
      // *   賞味期限算出         * //
      // ************************** //
      getUseByDate();
    }
// 2009-02-06 H.Itou Add End
// 2015-10-06 S.Yamashita Add Start
    // ロットNoに値がない場合、自動算出
    if (XxcmnUtility.isBlankOrNull(params.get("LotNumber")))
    {
      // ************************** //
      // *   ロット情報算出       * //
      // ************************** //
      getLotMst();
    }
// 2015-10-06 S.Yamashita Add End

    // ******************************* //
    // *   必須チェック              * //
    // ******************************* //
    messageTextCheck(exceptions);
    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // ******************************* //
    // *   処理タイプチェック        * //
    // ******************************* //
    productResultTypeCheck(exceptions);
    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
// 2008-10-23 H.Itou Add Start 倉庫が相手先在庫管理か伊藤園在庫管理かチェックする。
    // ************************ //
    // *    納入先情報取得    * //
    // ************************ //
    getLocationData();

    // ************************** //
    // *   倉庫管理元チェック   * //
    // ************************** //
    customerStockWhseCheck();
// 2008-10-23 H.Itou Add End

    // ******************************* //
    // *   在庫クローズチェック      * //
    // ******************************* //
    stockCloseCheck(exceptions);
    // 例外があった場合、例外メッセージを出力し、処理終了
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

// 2015-10-06 S.Yamashita Del Start
//    // ******************************* //
//    // *   ロット存在確認チェック    * //
//    // ******************************* //
//    // 新規登録かつ 品目区分が5：製品の場合、実行
//    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag) && XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
//    {
//      lotCheck(exceptions);
//      // 例外があった場合、例外メッセージを出力し、処理終了
//      if (exceptions.size() > 0)
//      {
//        OAException.raiseBundledOAException(exceptions);
//      }      
//    }
// 2015-10-06 S.Yamashita Del End
    
    // ******************************* //
    // *   引当可能数量チェック      * //
    // ******************************* //
    // 更新の場合、実行
    if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      paramsRet = reservedQuantityCheck(exceptions);
    // 新規の場合、戻り値にデフォルト値を設定
    } else
    {
      paramsRet.put("PlSqlRet", XxcmnConstants.RETURN_SUCCESS); 
    }
    return paramsRet; 
  }

  /***************************************************************************
   * 登録処理を行います。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String insProcess()
  {
    // 外注出来高情報取得
    HashMap params = getAllDataHashMap();
    String productResultType = (String)params.get("ProductResultType"); // 処理タイプ
    String testCode          = (String)params.get("TestCode");          // 試験有無区分
// 2015-10-06 S.Yamashita Add Start
    String lotNumber         = (String)params.get("LotNumber");         // ロットNo
    String qtInspectReqNo    = (String)params.get("QtInspectReqNo");    // 品詞検査依頼No
// 2015-10-06 S.Yamashita Add End
    
    // ************************ //
    // *     在庫単価取得     * //
    // ************************ //
    getStockValue();

    // ************************ //
    // *    発注番号取得      * //
    // ************************ //
    // 処理タイプ2:即時仕入の場合
    if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      getPoNumber();
    }

// 2008-10-23 H.Itou Del Start チェック処理時に取得するため、削除
//    // ************************ //
//    // *    納入先情報取得    * //
//    // ************************ //
//    getLocationData();
// 2008-10-23 H.Itou Del End
// 2015-10-06 S.Yamashita Add Start
    // 既存ロットを使用しない場合
    if(XxcmnUtility.isBlankOrNull(lotNumber))
    {
// 2015-10-06 S.Yamashita Add End
      // ************************ //
      // * ロットマスタ登録     * //
      // ************************ //
      // ロット登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insLotMst()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
// 2015-10-06 S.Yamashita Add Start
    }
// 2015-10-06 S.Yamashita Add End
    // ********************************** //
    // * 外注出来高実績(アドオン)登録   * //
    // ********************************** //
    // 外注出来高実績登録が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(insXxpoVendorSupplyTxns()))
    {
      return XxcmnConstants.RETURN_NOT_EXE;
    }

    // 処理タイプ1:相手先在庫管理の場合
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
    {
// 2015-10-06 S.Yamashita Add Start
      // 既存ロットを使用しない場合
      if(XxcmnUtility.isBlankOrNull(lotNumber))
      {
// 2015-10-06 S.Yamashita Add End
        // ************************ //
        // * ロット原価登録       * //
        // ************************ //
        // ロット原価登録処理が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(insLotCost()))
        {
          return XxcmnConstants.RETURN_NOT_EXE;
        }
    
// 2015-10-06 S.Yamashita Add Start
      }
// 2015-10-06 S.Yamashita Add End
      // ******************************** //
      // * 完了在庫トランザクション登録 * //
      // ******************************** //
      // 完了在庫トランザクション登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insInventoryPosting()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }

    // 処理タイプ2:即時仕入の場合
    } else if (XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
      // **************************** //
      // * 発注ヘッダ(アドオン)登録 * //
      // **************************** //
      // 発注ヘッダ(アドオン)登録が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insXxpoHeadersAll()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
      
      // **************************** //
      // * 発注ヘッダオープンIF登録 * //
      // **************************** //
      // 発注ヘッダオープンIF登録が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insPoHeadersIf()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
      
      // **************************** //
      // * 発注明細登録             * //
      // **************************** //
      // 発注明細オープンIF登録が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insPoLinesIf()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }

      // **************************** //
      // * 搬送明細登録             * //
      // **************************** //
      // 搬送明細オープンIF登録が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insPoDistributionsIf()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
    }
    
    // **************************** //
    // * 品質検査依頼情報作成     * //
    // **************************** //
    // 試験有無区分 1:有の場合
    if (XxpoConstants.QT_TYPE_ON.equals(testCode))
    {
// 2015-10-06 S.Yamashita Add Start
      // 既存ロットを使用しない場合、または品質検査依頼Noがない場合
      if (XxcmnUtility.isBlankOrNull(lotNumber) || XxcmnUtility.isBlankOrNull(qtInspectReqNo))
      {
// 2015-10-06 S.Yamashita Add End
        // 品質検査依頼情報登録が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(doQtInspection()))
        {
          return XxcmnConstants.RETURN_NOT_EXE;
        }
// 2015-10-06 S.Yamashita Add Start
      }
// 2015-10-06 S.Yamashita Add End
    }
    return XxcmnConstants.RETURN_SUCCESS;
  }

  /***************************************************************************
   * 更新処理を行います。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String updProcess()
  {
    // 外注出来高情報取得
    HashMap params = getAllDataHashMap();
    String testCode          = (String)params.get("TestCode");          // 試験有無区分
    String productedQuantity = (String)params.get("ProductedQuantity"); // 外注出来高数量
    Number conversionFactor  = (Number)params.get("ConversionFactor");  // 換算入数
    Number quantity          = (Number)params.get("Quantity");          // 数量
    String productResultType = (String)params.get("ProductResultType"); // 処理タイプ
// 2009-02-18 H.Itou Add Start 本番障害#1096
    String createLotDiv      = (String)params.get("CreateLotDiv");      // 作成区分
// 2009-02-18 H.Itou Add End
    
    // ********************************** //
    // * 外注出来高実績(アドオン)更新   * //
    // ********************************** //
    // 外注出来高実績登録が正常終了でない場合
    if (XxcmnConstants.RETURN_NOT_EXE.equals(updXxpoVendorSupplyTxns()))
    {
      return XxcmnConstants.RETURN_NOT_EXE;
    }
    
    // 数量が画面の外注出来高数量×換算入数と異なる場合のみ以下の処理を行う。
    if (Double.parseDouble(quantity.toString()) != Double.parseDouble(productedQuantity) * Double.parseDouble(conversionFactor.toString()))
    {
        // 処理タイプ1:相手先在庫管理の場合のみ完了在庫トランザクション作成
      if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
      {
// 2008-10-23 H.Itou Del Start チェック処理時に取得するため、削除
//        // ************************ //
//        // *    納入先情報取得    * //
//        // ************************ //
//        getLocationData();
// 2008-10-23 H.Itou Del End
    
        // ******************************** //
        // * 完了在庫トランザクション登録 * //
        // ******************************** //
        // 完了在庫トランザクション登録処理が正常終了でない場合
        if (XxcmnConstants.RETURN_NOT_EXE.equals(insInventoryPosting()))
        {
          return XxcmnConstants.RETURN_NOT_EXE;
        }              
      }
// 2009-02-18 H.Itou Del Start 本番障害#1096 更新でも品質検査を新規で作成する場合があるので、移動。      
//      // **************************** //
//      // * 品質検査依頼情報作成     * //
//      // **************************** //
//      // 試験有無区分 1:有の場合のみ実行
//      if (XxpoConstants.QT_TYPE_ON.equals(testCode))
//      {
//        // 検査依頼No取得
//        getQtInspectReqNo();
//      
//        // 品質検査依頼情報登録が正常終了でない場合
//        if (XxcmnConstants.RETURN_NOT_EXE.equals(doQtInspection()))
//        {
//          return XxcmnConstants.RETURN_NOT_EXE;
//        }
//      }
// 2009-02-18 H.Itou Del End
    }
// 2009-02-18 H.Itou Add Start 本番障害#1096
    // **************************** //
    // * 品質検査依頼情報作成     * //
    // **************************** //
    // ・試験有無区分 1:有
    // ・処理タイプ1:相手先在庫管理かつ、作成区分2:相手先在庫計上
    //   または、
    //   処理タイプ2:即時仕入かつ、作成区分3:出来高報告即時仕入
    if (XxpoConstants.QT_TYPE_ON.equals(testCode)
// 2009-03-02 H.Itou Mod Start 本番障害#32 作成区分は見ない。
//      && (((XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
//        && "2".equals(createLotDiv))
//      || ((XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
//        && "3".equals(createLotDiv))))
        )
// 2009-03-02 H.Itou Mod End
    {
      // 品質検査依頼情報登録が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(doQtInspection()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }
    }
// 2009-02-18 H.Itou Add End
    return XxcmnConstants.RETURN_SUCCESS;
  }
  
 /***************************************************************************
   * 登録・更新処理を行います。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String mainProcess()
  {
    // 外注出来高情報取得
    HashMap params = getAllDataHashMap();
    Object processFlag    = (Object)params.get("ProcessFlag"); // 処理フラグ

    // 処理フラグが1:登録の場合
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag))
    {
      // 登録処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(insProcess()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }      

    // 処理フラグが2:更新の場合
    } else if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      // 更新処理が正常終了でない場合
      if (XxcmnConstants.RETURN_NOT_EXE.equals(updProcess()))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }      
    }
    return XxcmnConstants.RETURN_SUCCESS;
  }

  /***************************************************************************
   * コンカレント：標準発注インポート発行処理です。(登録画面用)
   * @return String - リターンコード
   ***************************************************************************
   */
  public String doImportPo()
  {
    // 外注出来高情報取得
    HashMap params = getAllDataHashMap();
    String productResultType = (String)params.get("ProductResultType"); // 処理タイプ
    Object processFlag       = (Object)params.get("ProcessFlag");       // 処理フラグ
    
    // 処理フラグ1:登録かつ、処理タイプ2:即時仕入の場合のみ実行
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag) && XxpoConstants.PRODUCT_RESULT_TYPE_P.equals(productResultType))
    {
    
      return XxpoUtility.doImportStandardPurchaseOrders(
                            getOADBTransaction(), // トランザクション
                            params                // パラメータ
                            );      
    }
    return XxcmnConstants.RETURN_SUCCESS;
  }
   
  /***************************************************************************
   * 終了処理を行うメソッドです。(登録画面用)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doEndOfProcess() throws OAException
  {
    // 外注出来高情報取得
    HashMap params = getAllDataHashMap();
    Number txnsId      = (Number)params.get("TxnsId");      //実績ID
    Object processFlag = (Object)params.get("ProcessFlag"); // 処理フラグ
      
    // VO初期化処理(更新画面として再表示します。)
    initializeMake();

    // 検索
    doSearch(txnsId.toString());
    
    // 処理フラグが1:登録の場合
    if (XxpoConstants.PROCESS_FLAG_I.equals(processFlag))
    {
      // 登録完了メッセージ
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30041, 
        null, 
        OAException.INFORMATION, 
        null);

    // 処理フラグが2:更新の場合
    } else if (XxpoConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      // 更新完了メッセージ
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30042, 
        null, 
        OAException.INFORMATION, 
        null);
    }
  } // doEndOfProcess
  
  /***************************************************************************
   * コミット処理を行うメソッドです。(登録画面用)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doCommit(
  ) throws OAException
  {
    // コミット
    XxpoUtility.commit(getOADBTransaction());
  } // doCommit
  
  /***************************************************************************
   * ロールバック処理を行うメソッドです。(登録画面用)
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void doRollBack()
  {
    // ロールバック
    XxpoUtility.rollBack(getOADBTransaction());
  } // doRollBack

  /**
   * 
   * Container's getter for XxpoVendorSupplyVO1
   */
  public XxpoVendorSupplyVOImpl getXxpoVendorSupplyVO1()
  {
    return (XxpoVendorSupplyVOImpl)findViewObject("XxpoVendorSupplyVO1");
  }


  /**
   * 
   * Container's getter for XxpoVendorSupplySearchVO1
   */
  public XxpoVendorSupplySearchVOImpl getXxpoVendorSupplySearchVO1()
  {
    return (XxpoVendorSupplySearchVOImpl)findViewObject("XxpoVendorSupplySearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoVendorSupplyPVO1
   */
  public XxpoVendorSupplyPVOImpl getXxpoVendorSupplyPVO1()
  {
    return (XxpoVendorSupplyPVOImpl)findViewObject("XxpoVendorSupplyPVO1");
  }

  /**
   * 
   * Container's getter for XxpoVendorSupplyMakeVO1
   */
  public XxpoVendorSupplyMakeVOImpl getXxpoVendorSupplyMakeVO1()
  {
    return (XxpoVendorSupplyMakeVOImpl)findViewObject("XxpoVendorSupplyMakeVO1");
  }

  /**
   * 
   * Container's getter for XxpoVendorSupplyMakePVO1
   */
  public XxpoVendorSupplyMakePVOImpl getXxpoVendorSupplyMakePVO1()
  {
    return (XxpoVendorSupplyMakePVOImpl)findViewObject("XxpoVendorSupplyMakePVO1");
  }
}
