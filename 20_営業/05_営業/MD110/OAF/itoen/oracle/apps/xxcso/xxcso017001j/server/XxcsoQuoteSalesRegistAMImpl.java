/*============================================================================
* ファイル名 : XxcsoQuoteSalesRegistAMImpl
* 概要説明   : 販売先用見積入力画面アプリケーション・モジュールクラス
* バージョン : 1.13
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-02 1.0  SCS及川領    新規作成
* 2009-02-24 1.1  SCS及川領    [CT1-010]通常店納価格導出ボタンﾀｲﾑｱｳﾄ修正
* 2009-03-24 1.2  SCS阿部大輔  【課題77対応】チェックの期間をプロファイル値に修正
* 2009-03-24 1.2  SCS阿部大輔  【T1_0138】ボタン制御を修正
* 2009-04-13 1.3  SCS阿部大輔  【T1_0299】CSV出力制御
* 2009-04-14 1.4  SCS阿部大輔  【T1_0442】見積書印刷制御
* 2009-04-16 1.5  SCS阿部大輔  【T1_0462】コピー時の顧客名を追加
* 2009-05-07 1.6  SCS柳平直人  【T1_0803】コピー時の商品名を追加
* 2009-05-18 1.7  SCS阿部大輔  【T1_1023】見積明細の原価割れチェックを修正
* 2009-05-29 1.8  SCS柳平直人  【T1_1247】改訂時の顧客名、商品名設定処理追加
*                              【T1_1249】CSV出力制御、見積書印刷制御を修正
* 2009-06-16 1.9  SCS阿部大輔  【T1_1257】マージン額の変更修正
* 2009-07-23 1.10 SCS阿部大輔  【0000806】マージン額／マージン率の計算対象変更
* 2009-08-31 1.11 SCS阿部大輔  【0001212】通常店納価格導出ボタンの見積区分を変更
* 2009-12-21 1.12 SCS阿部大輔  【E_本稼動_00535】営業原価対応
* 2011-05-17 1.13 SCS桐生和幸  【E_本稼動_02500】原価割れチェック方法の変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.BlobDomain;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.xxcso017001j.util.XxcsoQuoteConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import java.io.UnsupportedEncodingException;

/*******************************************************************************
 * 販売先用見積入力画面のアプリケーション・モジュールクラス
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSalesRegistAMImpl extends OAApplicationModuleImpl
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSalesRegistAMImpl()
  {
  }

  /*****************************************************************************
   * 実行区分「なし」の場合の初期化処理
   * @param quoteHeaderId 見積ヘッダーID
   *****************************************************************************
   */
  public void initDetails(
    String quoteHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // トランザクションを初期化
    rollback();
    
    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");
    }

    initVo.executeQuery();
    
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    headerVo.initQuery(quoteHeaderId);
    headerVo.first();

    if (quoteHeaderId == null || "".equals(quoteHeaderId.trim()))
    {
      // 見積ヘッダー
      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

      headerVo.insertRow(headerRow);

      // ボタンレンダリング処理
      initRender();
      
      // 初期値設定
      headerRow.setQuoteType(
        XxcsoQuoteConstants.QUOTE_SALES
      );
      headerRow.setStatus(
        XxcsoQuoteConstants.QUOTE_INPUT
      );
      headerRow.setPublishDate(
        initRow.getCurrentDate()
      );
      headerRow.setEmployeeNumber(
        initRow.getEmployeeNumber()
      );
      headerRow.setFullName(
        initRow.getFullName()
      );
      headerRow.setBaseCode(
        initRow.getWorkBaseCode()
      );
      headerRow.setBaseName(
        initRow.getWorkBaseName()
      );
      headerRow.setDelivPlace(
        XxcsoQuoteConstants.DEF_DELIV_PLACE
      );
      headerRow.setPaymentCondition(
        XxcsoQuoteConstants.DEF_PAYMENT_CONDITION
      );
      headerRow.setDelivPriceTaxType(
        XxcsoQuoteConstants.DEF_DELIV_PRICE_TAX_TYPE
      );
      headerRow.setStorePriceTaxType(
        XxcsoQuoteConstants.DEF_STORE_PRICE_TAX_TYPE
      );
      headerRow.setUnitType(
        XxcsoQuoteConstants.DEF_UNIT_TYPE
      );
    }
    else
    {
      // ボタンレンダリング処理
      initRender();
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 実行区分「COPY」の場合の初期化処理
   * @param quoteHeaderId 見積ヘッダーID
   *****************************************************************************
   */
  public void initDetailsCopy(
    String quoteHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // XxcsoQuoteHeadersFullVO1インスタンスの取得
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // XxcsoQuoteHeadersFullVO2インスタンスの取得
    XxcsoQuoteHeadersFullVOImpl headerVo2 = getXxcsoQuoteHeadersFullVO2();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO2");
    }

    // XxcsoQuoteLinesSalesFullVO1インスタンスの取得
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // XxcsoQuoteLinesSalesFullVO2インスタンスの取得
    XxcsoQuoteLinesSalesFullVOImpl lineVo2 = getXxcsoQuoteLinesSalesFullVO2();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO2");
    }

    // XxcsoQuoteSalesInitVO1インスタンスの取得
    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");
    }

    // 初期化
    headerVo.initQuery((String)null);
    headerVo.first();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);

    // 検索
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeadersFullVORowImpl headerRow2
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo2.first();

    // 初期化用VOの検索
    initVo.executeQuery();
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    // コピー
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setPublishDate(
      initRow.getCurrentDate()
    );
    headerRow.setAccountNumber(
      headerRow2.getAccountNumber()
    );
    headerRow.setEmployeeNumber(
      initRow.getEmployeeNumber()
    );
    headerRow.setFullName(
      initRow.getFullName()
    );
    headerRow.setBaseCode(
      initRow.getWorkBaseCode()
    );
    headerRow.setBaseName(
      initRow.getWorkBaseName()
    );
    headerRow.setDelivPlace(
      headerRow2.getDelivPlace()
    );
    headerRow.setPaymentCondition(
      headerRow2.getPaymentCondition()
    );
    headerRow.setQuoteSubmitName(
      headerRow2.getQuoteSubmitName()
    );
    headerRow.setStatus(
      /* 20090324_abe_T1_0138 START*/
      //XxcsoQuoteConstants.QUOTE_INPUT
      XxcsoQuoteConstants.QUOTE_INIT
      /* 20090324_abe_T1_0138 END*/
    );
    headerRow.setDelivPriceTaxType(
      headerRow2.getDelivPriceTaxType()
    );
    headerRow.setStorePriceTaxType(
      headerRow2.getStorePriceTaxType()
    );
    headerRow.setUnitType(
      headerRow2.getUnitType()
    );
    headerRow.setSpecialNote(
      headerRow2.getSpecialNote()
    );
    /* 20090416_abe_T1_0462 START*/
    headerRow.setPartyName(
      headerRow2.getPartyName()
    );
    /* 20090416_abe_T1_0462 END*/

    
    // 明細のコピー
    XxcsoQuoteLinesSalesFullVORowImpl lineRow2
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.first();
    
    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesSalesFullVORowImpl lineRow
        = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.createRow();

      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);
      
      // コピー
      lineRow.setInventoryItemId(
        lineRow2.getInventoryItemId()
      );
      lineRow.setInventoryItemCode(
        lineRow2.getInventoryItemCode()
      );
// 2009-05-08 【T1_0803】 Add Start
      lineRow.setItemShortName(
        lineRow2.getItemShortName()
      );
// 2009-05-08 【T1_0803】 Add End
      lineRow.setQuoteDiv(
        lineRow2.getQuoteDiv()
      );
      lineRow.setUsuallyDelivPrice(
        lineRow2.getUsuallyDelivPrice()
      );
      lineRow.setUsuallyStoreSalePrice(
        lineRow2.getUsuallyStoreSalePrice()
      );
      lineRow.setThisTimeDelivPrice(
        lineRow2.getThisTimeDelivPrice()
      );
      lineRow.setThisTimeStoreSalePrice( 
        lineRow2.getThisTimeStoreSalePrice() 
      );
      lineRow.setRemarks(
        lineRow2.getRemarks()
      );
      lineRow.setLineOrder(
        lineRow2.getLineOrder()
      );
      lineRow.setBusinessPrice(
        lineRow2.getBusinessPrice()
      );

      /* 20090616_abe_T1_1257 START*/
      lineRow.setBowlIncNum(
        lineRow2.getBowlIncNum()
      );
      lineRow.setCaseIncNum(
        lineRow2.getCaseIncNum()
      );
      /* 20090616_abe_T1_1257 END*/

      // コピーした後に初期化
      lineRow.setQuoteStartDate(initRow.getCurrentDate());

      Date currentDate = new Date(initRow.getCurrentDate());
      
      if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
            lineRow.getQuoteDiv())
         )
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));
      }
      else
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(3));
      }

      lineRow2 = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.next();
    }

    // カーソルを先頭にする
    lineVo.first();
    
    // ボタンレンダリング処理
    initRender();

    /* 20090324_abe_T1_0138 START*/
    headerRow.setStatus(
      XxcsoQuoteConstants.QUOTE_INPUT
    );
    /* 20090324_abe_T1_0138 END*/

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 実行区分「REVISION_UP」の場合の初期化処理
   * @param quoteHeaderId 見積ヘッダーID
   *****************************************************************************
   */
  public void initDetailsRevisionUp(
    String quoteHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // XxcsoQuoteHeadersFullVO1インスタンスの取得
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // XxcsoQuoteHeadersFullVO2インスタンスの取得
    XxcsoQuoteHeadersFullVOImpl headerVo2 = getXxcsoQuoteHeadersFullVO2();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO2");
    }

    // XxcsoQuoteLinesSalesFullVO1インスタンスの取得
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // XxcsoQuoteLinesSalesFullVO2インスタンスの取得
    XxcsoQuoteLinesSalesFullVOImpl lineVo2 = getXxcsoQuoteLinesSalesFullVO2();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO2");
    }

    // XxcsoQuoteSalesInitVO1インスタンスの取得
    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");
    }

    // 初期化
    headerVo.initQuery((String)null);
    headerVo.first();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    // 検索
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeadersFullVORowImpl headerRow2
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo2.first();

    headerVo.insertRow(headerRow);

    // 初期化用VOの検索
    initVo.executeQuery();
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    // 属性数を取得
    int attrNum = headerVo.getAttributeCount();

     // コピー
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setQuoteNumber(
      headerRow2.getQuoteNumber()
    );
    headerRow.setQuoteRevisionNumber(
      headerRow2.getQuoteRevisionNumber().add(1)
    );
    headerRow.setPublishDate(
      initRow.getCurrentDate()
    );
    headerRow.setAccountNumber(
      headerRow2.getAccountNumber()
    );
    headerRow.setEmployeeNumber(
      initRow.getEmployeeNumber()
    );
    headerRow.setFullName(
      initRow.getFullName()
    );
    headerRow.setBaseCode(
      initRow.getWorkBaseCode()
    );
    headerRow.setBaseName(
      initRow.getWorkBaseName()
    );
    headerRow.setDelivPlace(
      headerRow2.getDelivPlace()
    );
    headerRow.setPaymentCondition(
      headerRow2.getPaymentCondition()
    );
    headerRow.setQuoteSubmitName(
      headerRow2.getQuoteSubmitName()
    );
    headerRow.setStatus(
      /* 20090324_abe_T1_0138 START*/
      //XxcsoQuoteConstants.QUOTE_INPUT
      XxcsoQuoteConstants.QUOTE_INIT
      /* 20090324_abe_T1_0138 END*/
    );
    headerRow.setDelivPriceTaxType(
      headerRow2.getDelivPriceTaxType()
    );
    headerRow.setStorePriceTaxType(
      headerRow2.getStorePriceTaxType()
    );
    headerRow.setUnitType(
      headerRow2.getUnitType()
    );
    headerRow.setSpecialNote(
      headerRow2.getSpecialNote()
    );
// 2009-05-29 【T1_1247】 Add Start
    headerRow.setPartyName(
      headerRow2.getPartyName()
    );
// 2009-05-29 【T1_1247】 Add End

    // 改定元のステータスを旧版にする
    headerRow2.setStatus(XxcsoQuoteConstants.QUOTE_OLD);
    
    // 明細のコピー
    XxcsoQuoteLinesSalesFullVORowImpl lineRow2
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.first();
    
    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesSalesFullVORowImpl lineRow
        = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.createRow();
      
      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);

      // コピー
      lineRow.setInventoryItemId(
        lineRow2.getInventoryItemId()
      );
      lineRow.setInventoryItemCode(
        lineRow2.getInventoryItemCode()
      );
// 2009-05-29 【T1_1247】 Add Start
      lineRow.setItemShortName(
        lineRow2.getItemShortName()
      );
// 2009-05-29 【T1_1247】 Add End
      lineRow.setQuoteDiv(
        lineRow2.getQuoteDiv()
      );
      lineRow.setUsuallyDelivPrice(
        lineRow2.getUsuallyDelivPrice()
      );
      lineRow.setUsuallyStoreSalePrice(
        lineRow2.getUsuallyStoreSalePrice()
      );
      lineRow.setThisTimeDelivPrice(
        lineRow2.getThisTimeDelivPrice()
      );
      lineRow.setThisTimeStoreSalePrice(
        lineRow2.getThisTimeStoreSalePrice()
      );
      lineRow.setRemarks(
        lineRow2.getRemarks()
      );
      lineRow.setLineOrder(
        lineRow2.getLineOrder()
      );
      lineRow.setBusinessPrice(
        lineRow2.getBusinessPrice()
      );

      /* 20090616_abe_T1_1257 START*/
      lineRow.setBowlIncNum(
        lineRow2.getBowlIncNum()
      );
      lineRow.setCaseIncNum(
        lineRow2.getCaseIncNum()
      );
      /* 20090616_abe_T1_1257 END*/
      // コピーした後に初期化
      lineRow.setQuoteStartDate(initRow.getCurrentDate());
      Date currentDate = new Date(initRow.getCurrentDate());

      if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
            lineRow.getQuoteDiv())
         )
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));
      }
      else
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(3));
      }
      
      lineRow2 = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.next();
    }

    // カーソルを先頭にする
    lineVo.first();
    
    // ボタンレンダリング処理
    initRender();

    /* 20090324_abe_T1_0138 START*/
    headerRow.setStatus(
      XxcsoQuoteConstants.QUOTE_INPUT
    );
    /* 20090324_abe_T1_0138 END*/

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ポップリスト初期化処理
   *****************************************************************************
   */
  public void initPoplist()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // *************************
    // *****poplistの生成*******
    // *************************
    // *****見積種別
    XxcsoLookupListVOImpl quoteTypeLookupVo =
      getXxcsoQuoteTypeLookupVO();
    if (quoteTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteTypeListVO");
    }
    // lookupの初期化
    quoteTypeLookupVo.initQuery("XXCSO1_QUOTE_TYPE", "1");
      
    // *****ステータス
    XxcsoLookupListVOImpl quoteStatusLookupVo =
      getXxcsoQuoteStatusLookupVO();
    if (quoteStatusLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteStatusLookupVO");
    }
    // lookupの初期化
    quoteStatusLookupVo.initQuery("XXCSO1_QUOTE_STATUS", "1");
      
    // *****店納価格税区分
    XxcsoLookupListVOImpl delivPriceTaxTypeLookupVo =
      getXxcsoDelivPriceTaxTypeLookupVO();
    if (delivPriceTaxTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDelivPriceTaxDivLookupVO");
    }
    // lookupの初期化
    delivPriceTaxTypeLookupVo.initQuery("XXCSO1_TAX_DIVISION", "1");
      
    // *****小売価格税区分
    XxcsoLookupListVOImpl storePriceTaxTypeLookupVo
        = getXxcsoStorePriceTaxTypeLookupVO();
    if (storePriceTaxTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoStorePriceTaxTypLookupVO");
    }
    // lookupの初期化
    storePriceTaxTypeLookupVo.initQuery("XXCSO1_TAX_DIVISION", "1");

    // *****単価区分
    XxcsoLookupListVOImpl unitPriceDivLookupVo
        = getXxcsoUnitPriceDivLookupVO();
    if (unitPriceDivLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoUnitPriceDivLookupVO");
    }
    // lookupの初期化
    unitPriceDivLookupVo.initQuery("XXCSO1_UNIT_PRICE_DIVISION", "1");

    // *****見積区分
    XxcsoLookupListVOImpl quoteDivLookupVo = getXxcsoQuoteDivLookupVO();
    if (quoteDivLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteDivLookupVO");
    }
    // lookupの初期化
    quoteDivLookupVo.initQuery("XXCSO1_QUOTE_DIVISION", "1");

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 取消ボタン押下時処理
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 変更内容を初期化する
    rollback();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * コピーの作成ボタン押下時処理
   * @return HashMap URLパラメータ
   *****************************************************************************
   */
  public HashMap handleCopyCreateButton(
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 変更内容を初期化する
    rollback();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    HashMap params = new HashMap();

   // 見積番号
    params.put(
          XxcsoConstants.TRANSACTION_KEY1,
          headerRow.getQuoteHeaderId()
        );
   // 戻り先画面名称
    params.put(
      XxcsoConstants.TRANSACTION_KEY3,
      returnPgName
    );
    // 実行区分
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_COPY
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 
  }

  /*****************************************************************************
   * 無効にするボタン押下時処理
   * @return OAException 正常終了メッセージ
   *****************************************************************************
   */
  public OAException handleInvalidityButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 問屋帳合先用見積の存在チェックを行う
    validateReference();
    
    // 変更内容を初期化する
    rollback();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

   // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // ステータスを更新
    headerRow.setStatus( XxcsoQuoteConstants.QUOTE_INVALIDITY );

    // 保存処理を実行します。
    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_NUMBER
            + headerRow.getQuoteNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_REV_NUMBER
            + headerRow.getQuoteRevisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
          ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoQuoteConstants.TOKEN_VALUE_INVALID
        );

    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * 適用ボタン押下時処理
   * @return HashMap 正常終了メッセージ,URLパラメータ
   *****************************************************************************
   */
  public HashMap handleApplicableButton(
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    // 問屋帳合先用見積の存在チェックを行う
    validateReference();
    
    List errorList = new ArrayList();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // 入力チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    // 見積明細
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    // 顧客コード
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getAccountNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_ACCOUNT_NUMBER
         ,0
        );

    // 納入場所
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getDelivPlace()
         ,XxcsoQuoteConstants.TOKEN_VALUE_DELIV_PLACE
         ,0
        );

    // 支払条件
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getPaymentCondition()
         ,XxcsoQuoteConstants.TOKEN_VALUE_PAYMENT_CONDITION
         ,0
        );

    // 見積書提出先名
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getQuoteSubmitName()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_SUBMIT_NAME
         ,0
        );

    // 特記事項
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getSpecialNote()
         ,XxcsoQuoteConstants.TOKEN_VALUE_SPECIAL_NOTE
         ,0
        );

    int index = 0;
    
    while ( lineRow != null )
    {
      index++;

      //DB反映チェック
      errorList
        = validateLine(
            errorList
           ,lineRow
           ,index
          );

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // 保存処理を実行します。
    commit();

    HashMap params = new HashMap(3);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoQuoteConstants.TRANDIV_UPDATE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getQuoteHeaderId()
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY3
     ,returnPgName
    );

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_NUMBER
            + headerRow.getQuoteNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_REV_NUMBER
            + headerRow.getQuoteRevisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoQuoteConstants.RETURN_PARAM_URL
     ,params
    );
    returnValue.put(
      XxcsoQuoteConstants.RETURN_PARAM_MSG
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  /*****************************************************************************
   * 版の改訂ボタン押下時処理
   * @return HashMap URLパラメータ
   *****************************************************************************
   */
  public HashMap handleRevisionButton(
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 問屋帳合先用見積の存在チェックを行う
    validateReference();
    
    // 変更内容を初期化する
    rollback();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    HashMap params = new HashMap();

   // 見積番号
    params.put(
          XxcsoConstants.TRANSACTION_KEY1,
          headerRow.getQuoteHeaderId()
        );
    // 戻り先画面名称
    params.put(
      XxcsoConstants.TRANSACTION_KEY3
     ,returnPgName
    );
    // 実行区分
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_REVISION_UP
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 

  }

  /*****************************************************************************
   * 確定ボタン押下時処理
   * @return OAException 正常終了メッセージ
   *****************************************************************************
   */
  public OAException handleFixedButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      // 問屋帳合先用見積の存在チェックを行う
      validateReference();
    }
    
    List errorList = new ArrayList();
    
    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // 画面項目の入力チェック
    validateFixed();

    // ステータスを更新
    headerRow.setStatus( XxcsoQuoteConstants.QUOTE_FIXATION );

    // 保存処理を実行します。
    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_NUMBER
            + headerRow.getQuoteNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_REV_NUMBER
            + headerRow.getQuoteRevisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoQuoteConstants.TOKEN_VALUE_FIXATION
        );

    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * 見積書印刷ボタン押下時処理
   * @return OAException 正常終了メッセージ
   *****************************************************************************
   */
  public OAException handlePdfCreateButton()
  {

    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(headerRow.getStatus()) )
    {
// 2009-05-29 【T1_1249】 Mod Start
//      /* 20090414_abe_T1_0442 START*/
//      //if ( getTransaction().isDirty() )
//      //{
//      /* 20090414_abe_T1_0442 END*/
//        // 問屋帳合先用見積の存在チェックを行う
//        validateReference();
//
//        // 画面項目の入力チェック
//        validateFixed();
//
//        // 保存処理を実行します。
//        commit();
//      /* 20090414_abe_T1_0442 START*/
//      //}
//      /* 20090414_abe_T1_0442 END*/
      if ( getTransaction().isDirty() )
      {
        // データ変更がある場合のみ
        // 問屋帳合先用見積の存在チェックを行う
        validateReference();
      }
      // 画面項目の入力チェック
      validateFixed();
      // 保存処理を実行します。
      commit();
// 2009-05-29 【T1_1249】 Mod End
    }
    else
    {
      rollback();
    }

    // 見積書印刷PGをCALL
    NUMBER requestId = null;
    OracleCallableStatement stmt = null;
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := fnd_request.submit_request(");
      sql.append("         application       => 'XXCSO'");
      sql.append("        ,program           => 'XXCSO017A03C'");
      sql.append("        ,description       => NULL");
      sql.append("        ,start_time        => NULL");
      sql.append("        ,sub_request       => FALSE");
      sql.append("        ,argument1         => :2");
      sql.append("       );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getQuoteHeaderId().stringValue());

      stmt.execute();
      
      requestId = stmt.getNUMBER(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    if ( NUMBER.zero().equals(requestId) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(50);
        sql.append("BEGIN fnd_message.retrieve(:1); END;");

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.VARCHAR);

        stmt.execute();

        String errmsg = stmt.getString(1);

        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00310
           ,XxcsoConstants.TOKEN_CONC
           ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
           ,XxcsoConstants.TOKEN_CONCMSG
           ,errmsg
          );
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
          );
      }
      finally
      {
        try
        {
          if ( stmt != null )
          {
            stmt.close();
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
        }
      }
    }

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + requestId.stringValue()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoQuoteConstants.TOKEN_VALUE_START
        );

    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * CSV作成ボタン押下時処理
   *****************************************************************************
   */
  public OAException handleCsvCreateButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(headerRow.getStatus()) )
    {
// 2009-05-29 【T1_1249】 Mod Start
//      /* 20090414_abe_T1_0442 START*/
//      //if ( getTransaction().isDirty() )
//      //{
//      /* 20090414_abe_T1_0442 END*/
//        // 問屋帳合先用見積の存在チェックを行う
//        validateReference();
//
//        // 画面項目の入力チェック
//        validateFixed();
//
//        // 保存処理を実行します。
//        commit();
//      /* 20090414_abe_T1_0442 START*/
//      //}
//      /* 20090414_abe_T1_0442 END*/
      if ( getTransaction().isDirty() )
      {
        // データ変更がある場合のみ
        // 問屋帳合先用見積の存在チェックを行う
        validateReference();
      }
      // 画面項目の入力チェック
      validateFixed();
      // 保存処理を実行します。
      commit();
// 2009-05-29 【T1_1249】 Mod End
    }
    else
    {
      rollback();
    }

    // CSVファイル作成
    XxcsoCsvQueryVOImpl queryVo = getXxcsoCsvQueryVO1();
    String sql = queryVo.getQuery();

    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;

    // プロファイルの取得
    String clientEnc = txn.getProfile(XxcsoConstants.XXCSO1_CLIENT_ENCODE);
    if ( clientEnc == null || "".equals(clientEnc.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.XXCSO1_CLIENT_ENCODE
        );
    }

    StringBuffer sbFileData = new StringBuffer();

    try
    {
      stmt = (OracleCallableStatement)txn.createCallableStatement(sql, 0);
      stmt.setNUMBER(1, headerRow.getQuoteHeaderId());

      rs = (OracleResultSet)stmt.executeQuery();

      while ( rs.next() )
      {
        // 出力用バッファへ格納
        int rsIdx = 1;
        
        // 項目:見積種別
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積番号
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:版
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:発行日
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:顧客コード
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:顧客名
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:従業員番号
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:従業員氏名
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:拠点コード
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:拠点名
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:納入場所
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:支払条件
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積情報開始日
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積情報終了日
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積提出先名
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:店納価格税区分
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:小売価格税区分
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:単価税区分
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:ステータス
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:特記事項
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:商品コード
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:商品略称
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積区分
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:通常店納価格
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 START*/
        // 項目:通常店頭売価
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 END*/
        // 項目:今回店納価格
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 START*/
        // 項目:今回店頭売価
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 END*/
        // 項目:期間（開始）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:期間（終了）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:備考
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:並び順
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積種別（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:参照用見積番号（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:問屋帳合先名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積番号（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:版（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:発行日（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:顧客コード（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:顧客名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:問屋管理コード（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:問屋管理名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);

        // 項目:従業員番号（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:従業員氏名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:拠点コード（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:拠点名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:納入場所（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:支払条件（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積情報開始日（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積情報終了日（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積提出先名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:店納価格税区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:小売価格税区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:単価税区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:ステータス（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:特記事項（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:商品コード（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:商品略称（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:通常店納価格（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 START*/
        // 項目:通常店頭売価（帳合用）
        //sbFileData
        //  = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 END*/
        // 項目:今回店納価格（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 START*/
        // 項目:今回店頭売価（帳合用）
        //sbFileData
        //  = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        /* 20090413_abe_T1_0299 END*/
        // 項目:建値（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:売上値引（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:通常ＮＥＴ価格（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:今回ＮＥＴ価格（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:マージン額（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:マージン率（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:期間（開始）（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:期間（終了）（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:備考（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:並び順（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);


        // 項目:商品正式名称
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:JANコード
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:ケースJANコード
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:ITFコード
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:容器区分
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:定価（新）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), true);
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_CSV_CREATE
        );
    }
    finally
    {
      try
      {
        if ( rs != null )
        {
          rs.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }
    
    // VOへのファイル名、ファイルデータの設定
    XxcsoCsvDownVOImpl csvVo = getXxcsoCsvDownVO1();
    if ( csvVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVO1");
    }

    XxcsoCsvDownVORowImpl csvRowVo
      = (XxcsoCsvDownVORowImpl)csvVo.createRow();

    // *****CSVファイル名用日付文字列(yyyymmdd)
    StringBuffer sbDate = new StringBuffer(8);
    String nowDate = txn.getCurrentUserDate().dateValue().toString();
    sbDate.append(nowDate.substring(0, 4));
    sbDate.append(nowDate.substring(5, 7));
    sbDate.append(nowDate.substring(8, 10));

    // *****CSVファイル名の生成(見積番号_yyyymmdd_連番)
    StringBuffer sbFileName = new StringBuffer(120);
    sbFileName.append(headerRow.getQuoteNumber());
    sbFileName.append(XxcsoQuoteConstants.CSV_NAME_DELIMITER);
    sbFileName.append(sbDate);
    sbFileName.append(XxcsoQuoteConstants.CSV_NAME_DELIMITER);
    sbFileName.append((csvVo.getRowCount() + 1));
    sbFileName.append(XxcsoQuoteConstants.CSV_EXTENSION);

    try
    {
      // *****ファイル名、ファイルデータを設定
      csvRowVo.setFileName(new String(sbFileName));
      csvRowVo.setFileData(
        new BlobDomain(sbFileData.toString().getBytes(clientEnc))
      );
    }
    catch (UnsupportedEncodingException uae)
    {
      throw XxcsoMessage.createCsvErrorMessage(uae);
    }

    csvVo.last();
    csvVo.next();
    csvVo.insertRow(csvRowVo);

    // 成功メッセージを設定する
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoQuoteConstants.MSG_DISP_CSV);
    sbMsg.append(sbFileName);

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoQuoteConstants.MSG_DISP_OUT
        );
    
    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * 帳合問屋用入力画面へボタン押下時処理
   * @return HashMap URLパラメータ
   *****************************************************************************
   */
  public HashMap handleStoreButton()
  {

    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(headerRow.getStatus()) )
    {
      // 顧客タイプチェック
      validateAccount();

// 2009-05-29 【T1_1249】 Mod Start
//      /* 20090414_abe_T1_0442 START*/
//      //if ( getTransaction().isDirty() )
//      //{
//      /* 20090414_abe_T1_0442 END*/
//        // 問屋帳合先用見積の存在チェックを行う
//        validateReference();
//
//        // 画面項目の入力チェック
//        validateFixed();
//
//        // 保存処理を実行します。
//        commit();
//      /* 20090414_abe_T1_0442 START*/
//      //}
//      /* 20090414_abe_T1_0442 END*/
      if ( getTransaction().isDirty() )
      {
        // 問屋帳合先用見積の存在チェックを行う
        validateReference();
      }
      // 画面項目の入力チェック
      validateFixed();

      // 保存処理を実行します。
      commit();
// 2009-05-29 【T1_1249】 Mod End

    }
    else
    {
      rollback();
    }
    
    HashMap params = new HashMap();

   // 見積ヘッダーID
   params.put(
     XxcsoConstants.TRANSACTION_KEY1,
     ""
   );

   // 参照用見積ヘッダーID
   params.put(
     XxcsoConstants.TRANSACTION_KEY2,
     headerRow.getQuoteHeaderId()
   );

    // 戻り先画面名称
    params.put(
      XxcsoConstants.TRANSACTION_KEY3,
     ""
    );

    // 実行区分
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_FROM_SALES
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 

  }

  /*****************************************************************************
   * 行追加ボタン押下時処理（見積明細表）
   *****************************************************************************
   */
  public void handleAddLineButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 問屋帳合先用見積の存在チェックを行う
    validateReference();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    int maxSize
      = Integer.parseInt(txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE));
      
    if ( lineVo.getRowCount() == maxSize )
    {
      throw
        XxcsoMessage.createMaxRowException(
          XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_LINE_INFO
         ,String.valueOf(maxSize)
        );
    }
    
    // 新規明細行作成
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.createRow();

    // 初期化用VO行を取得
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();
    
    // 初期値の設定
    Date currentDate = new Date(initRow.getCurrentDate());
    lineRow.setQuoteDiv(XxcsoQuoteConstants.QUOTE_DIV_USUALLY);
    lineRow.setQuoteStartDate(initRow.getCurrentDate());
    lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));

    // 行の最後に追加
    lineVo.last();
    lineVo.next();
    lineVo.insertRow(lineRow);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 行削除ボタン押下時処理（見積明細表）
   *****************************************************************************
   */
  public void handleDelLineButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    // インスタンス取得
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    boolean existFlag = false;
    
    // 削除対象明細をチェック
    while ( lineRow != null )
    {
      if ( "Y".equals(lineRow.getSelectFlag()) )
      {
        existFlag = true;

        // 問屋帳合先見積の存在チェックを行う
        validateReference();
      }
      
      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    if ( ! existFlag )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00464);
    }
    
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // 帳合問屋情報で使用していない場合は削除します。
    lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( "Y".equals(lineRow.getSelectFlag()) )
      {
        // 選択されている明細行を削除します。
        lineVo.removeCurrentRow();
      }

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    // カーソルを先頭にする
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 通常店納価格導出ボタン押下時処理（見積明細表）
   *****************************************************************************
   */
  public void handleRegularPriceButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    XxcsoUsuallyDelivPriceVOImpl usuallyVo = getXxcsoUsuallyDelivPriceVO1();

    if ( usuallyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoUsuallyDelivPriceVO1");
    }

   // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

   // 見積明細
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
/* 20090831_abe_0001212 START*/
      //// 見積区分が通常以外の場合、通常店納価格を自動導出します。
      //if ( ! XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
      //       lineRow.getQuoteDiv()) )
      //{
/* 20090831_abe_0001212 END*/
      if ( "Y".equals(lineRow.getSelectFlag()) )
      {
        // 問屋帳合先用見積の存在チェックを行う
        validateReference();

        // 検索実行
        usuallyVo.initQuery(
          headerRow.getAccountNumber(),
          lineRow.getInventoryItemId()
        );

        // 通常店納価格取得
        XxcsoUsuallyDelivPriceVORowImpl usuallyRow
          = (XxcsoUsuallyDelivPriceVORowImpl)usuallyVo.first();

        //通常店納価格が取得できた場合
        if ( usuallyRow != null )
        {
          // 取得した通常店納価格を設定
          lineRow.setUsuallyDelivPrice(usuallyRow.getUsuallyDelivPrice());
        }
      }
/* 20090831_abe_0001212 START*/
      //}
/* 20090831_abe_0001212 END*/
      
      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    // カーソルを先頭にする
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * 見積区分が変更されたら期間（終了）も変更する処理
   * @param quoteLineId 見積明細ID
   *****************************************************************************
   */
  public void handleDivChange(
    String quoteLineId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 問屋帳合先用見積の存在チェックを行う
    validateReference();
    
    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // XxcsoQuoteSalesInitVO1インスタンスの取得
    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");
    }

    // 見積明細
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( quoteLineId.equals(lineRow.getQuoteLineId().stringValue()) )
      {
        // システム日付取得
        XxcsoQuoteSalesInitVORowImpl initRow
          = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

        if ( lineRow.getQuoteStartDate() != null )
        {
          Date currentDate = new Date(lineRow.getQuoteStartDate());

          // 見積区分が「1」の場合は、1年後。それ以外は3ヶ月後
          if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
                 lineRow.getQuoteDiv())
             )
          {
            lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));
          }
          else
          {
            lineRow.setQuoteEndDate((Date)currentDate.addMonths(3));
          }
        }
        break;
      }

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 確定チェック処理
   *****************************************************************************
   */
  private void validateFixed()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 入力チェックを行います。
    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }
    
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
    XxcsoQtApTaxRateVOImpl taxVo = getXxcsoQtApTaxRateVO1();
    if ( taxVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQtApTaxRateVO1");
    }
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End

    errorList = validateHeader(errorList);

    /* 20090518_abe_T1_1023 START*/
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    /* 20090518_abe_T1_1023 END*/

    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
    XxcsoQtApTaxRateVORowImpl taxRow
      = (XxcsoQtApTaxRateVORowImpl)taxVo.first();
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End

    /* 20090324_abe_課題77 START*/
    //プロファイルの取得
    int period_Day = 0;
    try{
      period_Day =  Integer.parseInt(txn.getProfile(XxcsoQuoteConstants.PERIOD_DAY));
    }
    catch ( NumberFormatException e )
    {
      period_Day = 0;
    }
    /* 20090324_abe_課題77 END*/

// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
    //仮払税率の存在チェック
    double taxrate = -1;
    if ( taxRow != null )
    {
      taxrate = taxRow.getApTaxRate().doubleValue();
    }
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End

    int index = 0;
    while ( lineRow != null )
    {
      index++;
      validateLine(
        errorList
       ,lineRow
       ,index
      );

      validateFixedLine(
        errorList
       /* 20090518_abe_T1_1023 START*/
       ,headerRow
       /* 20090518_abe_T1_1023 END*/
       ,lineRow
       ,index
       /* 20090324_abe_課題77 START*/
       ,period_Day
       /* 20090324_abe_課題77 END*/
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
       ,taxrate
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End
      );

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    if ( index == 0 )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00451);
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 問屋帳合先用見積の存在チェック処理
   *****************************************************************************
   */
  private void validateReference()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoReferenceQuoteVOImpl refVo = getXxcsoReferenceQuoteVO1();
    if ( refVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoReferenceQuoteVO1");
    }

    List errorList = new ArrayList();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // 問屋帳合先用見積が存在しているかを確認
    refVo.initQuery(headerRow.getQuoteHeaderId());

    XxcsoReferenceQuoteVORowImpl refRow
      = (XxcsoReferenceQuoteVORowImpl)refVo.first();

    while ( refRow != null )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00223
           ,XxcsoConstants.TOKEN_PARAM9
           ,refRow.getQuoteNumber()
          );

      errorList.add(error);

      refRow = (XxcsoReferenceQuoteVORowImpl)refVo.next();

    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    XxcsoUtils.debug(txn, "[END]");

  }

  
  /*****************************************************************************
   * 見積ヘッダー項目のチェック処理
   * @param errorList エラーリスト
   *****************************************************************************
   */
  private List validateHeader(
    List errorList
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 入力チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    ///////////////////////////////////
    // 値検証（見積ヘッダー）
    ///////////////////////////////////
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // 発行日
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getPublishDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_PUBLISH_DATE
         ,0
        );

    // 顧客コード
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getAccountNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_ACCOUNT_NUMBER
         ,0
        );

    // 納入場所
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getDelivPlace()
         ,XxcsoQuoteConstants.TOKEN_VALUE_DELIV_PLACE
         ,0
        );

    // 支払条件
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getPaymentCondition()
         ,XxcsoQuoteConstants.TOKEN_VALUE_PAYMENT_CONDITION
         ,0
        );

    // 見積書提出先名
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getQuoteSubmitName()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_SUBMIT_NAME
         ,0
        );

    // 特記事項
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getSpecialNote()
         ,XxcsoQuoteConstants.TOKEN_VALUE_SPECIAL_NOTE
         ,0
        );


    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 見積明細項目のチェック処理（DB登録用）
   * @param errorList     エラーリスト
   * @param lineRow       見積明細行インスタンス
   * @param index         対象行
   *****************************************************************************
   */
  private List validateLine(
    List                              errorList
   ,XxcsoQuoteLinesSalesFullVORowImpl lineRow
   ,int                               index
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // 入力チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    ///////////////////////////////////
    // 値検証（見積明細）
    ///////////////////////////////////
    //価格がnullの場合意は「0」に置き換える
/* 20090723_abe_0000806 START*/
    //if ( lineRow.getUsuallyDelivPrice() == null )
    //{
    //  lineRow.setUsuallyDelivPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getUsuallyStoreSalePrice() == null )
    //{
    //  lineRow.setUsuallyStoreSalePrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getThisTimeDelivPrice() == null )
    //{
    //  lineRow.setThisTimeDelivPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getThisTimeStoreSalePrice() == null )
    //{
    //  lineRow.setThisTimeStoreSalePrice(XxcsoQuoteConstants.DEF_PRICE);
    //}
/* 20090723_abe_0000806 END*/

    // 商品コード
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getInventoryItemId()
         ,XxcsoQuoteConstants.TOKEN_VALUE_INVENTORY_ITEM_ID
         ,index
        );

    // 通常店納価格
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getUsuallyDelivPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_DELIV_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 通常店頭売価
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getUsuallyStoreSalePrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_STORE_SALE_PRICE
         ,2
         ,6
         ,true
         ,false
         ,false
         ,index
        );

    // 今回店納価格
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getThisTimeDelivPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_DELIV_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 今回店頭売価
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getThisTimeStoreSalePrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_STORE_SALE_PRICE
         ,2
         ,6
         ,true
         ,false
         ,false
         ,index
        );

    // 並び順
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getLineOrder()
         ,XxcsoQuoteConstants.TOKEN_VALUE_LINE_ORDER
         ,0
         ,2
         ,true
         ,false
         ,false
         ,index
        );

    // 備考
    errorList
      = util.checkIllegalString(
          errorList
         ,lineRow.getRemarks()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REMARKS
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }
  
  /*****************************************************************************
   * 見積明細項目のチェック処理（確定チェック）
   * @param errorList     エラーリスト
   * @param headerRow     見積ヘッダ行インスタンス
   * @param lineRow       見積明細行インスタンス
   * @param index         対象行
   * @param period_Daye   プロファイル値←20090324_abe_課題77 ADD
   *****************************************************************************
   */
  private List validateFixedLine(
    List                              errorList
   /* 20090518_abe_T1_1023 START*/
   ,XxcsoQuoteHeadersFullVORowImpl  headerRow
   /* 20090518_abe_T1_1023 END*/
   ,XxcsoQuoteLinesSalesFullVORowImpl lineRow
   ,int                               index
   /* 20090324_abe_課題77 START*/
   ,int                               period_Daye
   /* 20090324_abe_課題77 END*/
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
   ,double                            taxrate
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End
  )
  {
    OADBTransaction txn = getOADBTransaction();
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
    double taxratecul = 0;
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    // 必須チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    /* 20090616_abe_T1_1257 START*/
    // 商品コード
    //errorList
    //  = util.requiredCheck(
    //      errorList
    //     ,lineRow.getInventoryItemId()
    //     ,XxcsoQuoteConstants.TOKEN_VALUE_INVENTORY_ITEM_ID
    //     ,index
    //    );
    /* 20090616_abe_T1_1257 END*/

    // 期間（開始）
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuoteStartDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_START_DATE
         ,index
        );

    // 期間（終了）
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuoteEndDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_END_DATE
         ,index
        );
    
    // 期間チェック
    if ( lineRow.getQuoteStartDate() != null &&
         lineRow.getQuoteEndDate()   != null
       )
    {
      Date currentDate = new Date(initRow.getCurrentDate());
      Date currentDate2 = new Date(lineRow.getQuoteStartDate());

      /* 20090324_abe_課題77 START*/
      //Date limitDate = (Date)currentDate.addJulianDays(-30, 0);
      Date limitDate = (Date)currentDate.addJulianDays(-period_Daye, 0);

      // システム日付より30日前まで入力可能【削除】
      // システム日付よりプロファイル値日前まで入力可能
      /* 20090324_abe_課題77 END*/
      if ( lineRow.getQuoteStartDate().compareTo(limitDate) < 0 )
      {
        XxcsoUtils.debug(txn, limitDate);

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00463
             /* 20090324_abe_課題77 START*/
             ,XxcsoConstants.TOKEN_PERIOD
             ,String.valueOf(period_Daye)
             /* 20090324_abe_課題77 END*/
             ,XxcsoConstants.TOKEN_INDEX
             ,String.valueOf(index)
            );
        errorList.add(error);
      }

      // 見積区分が通常の場合
      if( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(lineRow.getQuoteDiv()) )
      {
        // 期間（開始）より１年以内
        limitDate = (Date)currentDate2.addMonths(12);

        if ( lineRow.getQuoteEndDate().compareTo(limitDate) > 0 ||
             lineRow.getQuoteEndDate().compareTo(
                                         lineRow.getQuoteStartDate()) < 0
           )
        {
          XxcsoUtils.debug(txn, limitDate);

          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00462,
                XxcsoConstants.TOKEN_VALUES,
                XxcsoQuoteConstants.TOKEN_VALUE_USUALLY,
                XxcsoConstants.TOKEN_PERIOD,
                XxcsoQuoteConstants.TOKEN_VALUE_ONE_YEAR,
                XxcsoConstants.TOKEN_INDEX,
                String.valueOf(index)
              );
          errorList.add(error);
        }
      }
      else
      {
        // 期間（開始）より3ヶ月以内
        limitDate = (Date)currentDate2.addMonths(3);

        if ( lineRow.getQuoteEndDate().compareTo(limitDate) > 0 ||
             lineRow.getQuoteEndDate().compareTo(
                                         lineRow.getQuoteStartDate()) < 0
           )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00462,
                XxcsoConstants.TOKEN_VALUES,
                XxcsoQuoteConstants.TOKEN_VALUE_EXCULDING_USUALLY,
                XxcsoConstants.TOKEN_PERIOD,
                XxcsoQuoteConstants.TOKEN_VALUE_THREE_MONTHS,
                XxcsoConstants.TOKEN_INDEX,
                String.valueOf(index)
              );
          errorList.add(error);
        }
      }
    }
/* 20090616_abe_T1_1257 START*/
    if (lineRow.getInventoryItemId() != null) 
    {
/* 20090723_abe_0000806 START*/
//      // 入数のチェック
//      if ( lineRow.getCaseIncNum() != null &&
//           lineRow.getBowlIncNum() != null
//         )
//      {      
//        double caseincnum      = lineRow.getCaseIncNum().doubleValue();
//        double bowlincnum      = lineRow.getBowlIncNum().doubleValue();
//
//        if(((caseincnum == 0) &&
//            (headerRow.getUnitType().equals("2"))) ||
//           ((bowlincnum == 0) &&
//            (headerRow.getUnitType().equals("3")))
//          )
//        {
//            OAException error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00574,
//                  XxcsoConstants.TOKEN_INDEX,
//                  String.valueOf(index)
//                );
//            errorList.add(error);
//        }
/* 20090723_abe_0000806 END*/
/* 20090616_abe_T1_1257 END*/
      // 通常か特売の場合は、店納価格の原価割れチェック
      if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(lineRow.getQuoteDiv()) ||
           XxcsoQuoteConstants.QUOTE_DIV_BARGAIN.equals(lineRow.getQuoteDiv())
         )
      {
/* 20090723_abe_0000806 START*/
        // 必須チェック
        if(lineRow.getUsuallyDelivPrice() == null) 
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getUsuallyDelivPrice()
               ,XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_DELIV_PRICE
               ,index
              );
        }
        else
        {
          // 入数のチェック
          if ( lineRow.getCaseIncNum() != null &&
               lineRow.getBowlIncNum() != null
             )
          {
            double caseincnum      = lineRow.getCaseIncNum().doubleValue();
            double bowlincnum      = lineRow.getBowlIncNum().doubleValue();

            if(((caseincnum == 0) &&
                (headerRow.getUnitType().equals("2"))) ||
               ((bowlincnum == 0) &&
                (headerRow.getUnitType().equals("3")))
              )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00574,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
/* 20090723_abe_0000806 END*/
            String usuallyDelivPriceRep 
              = lineRow.getUsuallyDelivPrice().replaceAll(",", "");
/* 20090723_abe_0000806 START*/
            //String thisTimeDelivPriceRep 
            //  = lineRow.getThisTimeDelivPrice().replaceAll(",", "");
/* 20090723_abe_0000806 END*/
            /* 20090518_abe_T1_1023 START*/
            String unittype        = headerRow.getUnitType();
            /* 20090616_abe_T1_1257 START*/
            //double caseincnum      = lineRow.getCaseIncNum().doubleValue();
            //double bowlincnum      = lineRow.getBowlIncNum().doubleValue();
            /* 20090616_abe_T1_1257 END*/
            /* 20090518_abe_T1_1023 END*/
            /* 20091221_abe_E_本稼動_00535 START*/
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
            //店納価格税区分が"2"(税込価格)の場合、仮払税率のチェック
            if (headerRow.getDelivPriceTaxType().equals("2"))
            {
              //仮払消費税が取得できている場合
              if (taxrate != -1)
              {
                //引数の税率を設定
                taxratecul = taxrate;
              }
              else
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00613,
                      XxcsoConstants.TOKEN_COLUMN,
                      XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_DELIV_PRICE,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
            //店納価格税区分が"1"(税抜価格)の場合
            else
            {
              //営業原価でチェックする為、税率に1を設定
              taxratecul = 1;
            }
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod Start
//            if (lineRow.getBusinessPrice() != null)
            if ((lineRow.getBusinessPrice() != null) &&
                (taxrate != -1)
               )
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod End
            {
            /* 20091221_abe_E_本稼動_00535 END*/
              double businessPrice = lineRow.getBusinessPrice().doubleValue();
              try
              {
                double usuallyDelivPrice  = Double.parseDouble(usuallyDelivPriceRep);
                // 通常店納価格
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod Start
//                /* 20090518_abe_T1_1023 START*/
//                if ( (usuallyDelivPrice <= businessPrice && unittype.equals("1") ) ||
//                     ((usuallyDelivPrice / caseincnum <= businessPrice ||
//                      caseincnum == 0) && unittype.equals("2") ) || 
//                     ((usuallyDelivPrice / bowlincnum <= businessPrice ||
//                      bowlincnum == 0) && unittype.equals("3"))
//                   )
//                //if ( usuallyDelivPrice <= businessPrice )
//                /* 20090518_abe_T1_1023 END*/
                if ( (usuallyDelivPrice <= businessPrice * taxratecul && unittype.equals("1") ) ||
                     ((usuallyDelivPrice / caseincnum <= businessPrice * taxratecul ||
                      caseincnum == 0) && unittype.equals("2") ) || 
                     ((usuallyDelivPrice / bowlincnum <= businessPrice * taxratecul ||
                      bowlincnum == 0) && unittype.equals("3"))
                   )
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod End
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00461,
                        XxcsoConstants.TOKEN_COLUMN,
                        XxcsoQuoteConstants.TOKEN_VALUE_USUALLY,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
              catch ( NumberFormatException e )
              {
                XxcsoUtils.debug(txn, "NumberFormatException");
              }
            /* 20091221_abe_E_本稼動_00535 START*/
            }
            /* 20091221_abe_E_本稼動_00535 END*/
/* 20090723_abe_0000806 START*/
          }
        }
/* 20090723_abe_0000806 END*/
        // 今回店納価格は、入力された場合のみ原価割れチェック
        if(lineRow.getThisTimeDelivPrice() != null)
        {
          // 入数のチェック
          if ( lineRow.getCaseIncNum() != null &&
               lineRow.getBowlIncNum() != null
             )
          {
            double caseincnum      = lineRow.getCaseIncNum().doubleValue();
            double bowlincnum      = lineRow.getBowlIncNum().doubleValue();

            if(((caseincnum == 0) &&
                (headerRow.getUnitType().equals("2"))) ||
               ((bowlincnum == 0) &&
                (headerRow.getUnitType().equals("3")))
              )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00574,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }

            String unittype        = headerRow.getUnitType();
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add Start
            //税率初期化
            taxratecul = 0;
            //店納価格税区分が"2"(税込価格)の場合、仮払税率のチェック
            if(headerRow.getDelivPriceTaxType().equals("2"))
            {
              //仮払消費税が取得できている場合
              if(taxrate != -1)
              {
                //引数の仮払税率を設定
                taxratecul = taxrate;
              }
              else
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00613,
                      XxcsoConstants.TOKEN_COLUMN,
                      XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_DELIV_PRICE,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
            //店納価格税区分が"1"(税抜価格)の場合
            else
            {
              //営業原価でチェックする為、税率に1を設定
              taxratecul = 1;
            }
// 2011-05-17 Ver1.13 [E_本稼動_02500] Add End
            /* 20091221_abe_E_本稼動_00535 START*/
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod Start
//            if (lineRow.getBusinessPrice() != null)
            if ((lineRow.getBusinessPrice() != null) &&
                (taxrate != -1)
               )
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod End
            {
            /* 20091221_abe_E_本稼動_00535 END*/
              double businessPrice = lineRow.getBusinessPrice().doubleValue();
              try
              {
                /* 20090723_abe_0000806 START*/
                //double thisTimeDelivPrice = Double.parseDouble(thisTimeDelivPriceRep);
                  String thisTimeDelivPriceRep 
                    = lineRow.getThisTimeDelivPrice().replaceAll(",", "");
                  double thisTimeDelivPrice = Double.parseDouble(thisTimeDelivPriceRep);
                /* 20090723_abe_0000806 END*/

                // 今回店納価格
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod Start
//                /* 20090518_abe_T1_1023 START*/
//                if ( (thisTimeDelivPrice <= businessPrice && unittype.equals("1") ) ||
//                    ((thisTimeDelivPrice / caseincnum <= businessPrice ||
//                      caseincnum == 0) && unittype.equals("2") ) || 
//                     ((thisTimeDelivPrice / bowlincnum <= businessPrice ||
//                      bowlincnum == 0) && unittype.equals("3"))
//                   )
//                //if ( thisTimeDelivPrice <= businessPrice )
//                /* 20090518_abe_T1_1023 END*/
                if ( (thisTimeDelivPrice <= businessPrice * taxratecul && unittype.equals("1") ) ||
                    ((thisTimeDelivPrice / caseincnum <= businessPrice * taxratecul ||
                      caseincnum == 0) && unittype.equals("2") ) || 
                     ((thisTimeDelivPrice / bowlincnum <= businessPrice * taxratecul ||
                      bowlincnum == 0) && unittype.equals("3"))
                   )
// 2011-05-17 Ver1.13 [E_本稼動_02500] Mod End
                  {
                    OAException error
                      = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00461,
                          XxcsoConstants.TOKEN_COLUMN,
                          XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME,
                          XxcsoConstants.TOKEN_INDEX,
                          String.valueOf(index)
                        );
                    errorList.add(error);
                  }

              }
              catch ( NumberFormatException e )
              {
                XxcsoUtils.debug(txn, "NumberFormatException");
              }
            /* 20091221_abe_E_本稼動_00535 START*/
            }
            /* 20091221_abe_E_本稼動_00535 END*/
          }
        /* 20090723_abe_0000806 START*/
        }
        /* 20090723_abe_0000806 END*/
      }
      /* 20090723_abe_0000806 START*/
      // 新規導入か原価割れの場合
      if ( XxcsoQuoteConstants.QUOTE_DIV_INTRO.equals(lineRow.getQuoteDiv()) ||
           XxcsoQuoteConstants.QUOTE_DIV_COST.equals(lineRow.getQuoteDiv())
         )
      {
        // 通常店納価格の必須チェック
        if(lineRow.getUsuallyDelivPrice() == null) 
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getUsuallyDelivPrice()
               ,XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_DELIV_PRICE
               ,index
              );
        }
      }
      /* 20090723_abe_0000806 END*/
    }

    // 備考
    errorList
      = util.checkIllegalString(
          errorList
         ,lineRow.getRemarks()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REMARKS
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 顧客チェック処理
   *****************************************************************************
   */
  private void validateAccount()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoAccountTypeVOImpl accountVo = getXxcsoAccountTypeVO1();
    if ( accountVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAccountTypeVO1");
    }

    List errorList = new ArrayList();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // 顧客コードが存在しているかを確認
    accountVo.initQuery(headerRow.getAccountNumber());

    XxcsoAccountTypeVORowImpl accountRow
      = (XxcsoAccountTypeVORowImpl)accountVo.first();

    if ( accountRow == null )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00115
          );

      errorList.add(error);
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * ボタンレンダリング処理
   *****************************************************************************
   */
  private void initRender()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");
    }
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    initRow.setCopyCreateButtonRender(Boolean.FALSE);
    initRow.setInvalidityButtonRender(Boolean.FALSE);
    initRow.setApplicableButtonRender(Boolean.FALSE);
    initRow.setRevisionButtonRender(Boolean.FALSE);
    initRow.setFixedButtonRender(Boolean.FALSE);
    initRow.setQuoteSheetPrintButtonRender(Boolean.FALSE);
    initRow.setCsvCreateButtonRender(Boolean.FALSE);
    initRow.setInputTranceButtonRender(Boolean.FALSE);

    String status = headerRow.getStatus();
    if ( status == null || "".equals(status.trim()) )
    {
      initRow.setApplicableButtonRender(Boolean.TRUE);
    }
    else
    {
      /* 20090324_abe_T1_0138 START*/
      if ( XxcsoQuoteConstants.QUOTE_INIT.equals(status) )
      {
        initRow.setApplicableButtonRender(Boolean.TRUE);
      }
      /* 20090324_abe_T1_0138 END*/
      if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setApplicableButtonRender(Boolean.TRUE);
        initRow.setRevisionButtonRender(Boolean.TRUE);
        initRow.setFixedButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
        initRow.setInputTranceButtonRender(Boolean.TRUE);
      }
      if ( XxcsoQuoteConstants.QUOTE_INVALIDITY.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
      }
      if ( XxcsoQuoteConstants.QUOTE_OLD.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
      }
      if ( XxcsoQuoteConstants.QUOTE_FIXATION.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
        initRow.setInvalidityButtonRender(Boolean.TRUE);
        initRow.setInputTranceButtonRender(Boolean.TRUE);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * CSV行作成処理
   *****************************************************************************
   */
  private StringBuffer createCsvStatement(
    StringBuffer buffer
   ,String       value
   ,boolean      endFlag
  )
  {

    /* 20090413_abe_T1_0299 START*/
    if ( value == null )
    {
      value = "";
    }
    /* 20090413_abe_T1_0299 END*/

    buffer.append("\"");
    buffer.append(value);
    buffer.append("\"");

    if ( endFlag )
    {
      buffer.append("\r\n");
    }
    else
    {
      buffer.append(",");
    }

    return buffer;
  }

  /*****************************************************************************
   * コミット処理
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ロールバック処理
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    if ( getTransaction().isDirty() )
    {
      // ロールバックを行います。
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");

  }






  /**
   * 
   * Container's getter for XxcsoStorePriceTaxTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoStorePriceTaxTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoStorePriceTaxTypeLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUsuallyDelivPriceVO1
   */
  public XxcsoUsuallyDelivPriceVOImpl getXxcsoUsuallyDelivPriceVO1()
  {
    return (XxcsoUsuallyDelivPriceVOImpl)findViewObject("XxcsoUsuallyDelivPriceVO1");
  }



  /**
   * 
   * Container's getter for XxcsoQuoteDivLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteDivLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteDivLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUnitPriceDivLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoUnitPriceDivLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoUnitPriceDivLookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoDelivPriceTaxTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoDelivPriceTaxTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoDelivPriceTaxTypeLookupVO");
  }



  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017001j.server", "XxcsoQuoteSalesRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeadersFullVO1
   */
  public XxcsoQuoteHeadersFullVOImpl getXxcsoQuoteHeadersFullVO1()
  {
    return (XxcsoQuoteHeadersFullVOImpl)findViewObject("XxcsoQuoteHeadersFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLinesSalesFullVO1
   */
  public XxcsoQuoteLinesSalesFullVOImpl getXxcsoQuoteLinesSalesFullVO1()
  {
    return (XxcsoQuoteLinesSalesFullVOImpl)findViewObject("XxcsoQuoteLinesSalesFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeadersFullVO2
   */
  public XxcsoQuoteHeadersFullVOImpl getXxcsoQuoteHeadersFullVO2()
  {
    return (XxcsoQuoteHeadersFullVOImpl)findViewObject("XxcsoQuoteHeadersFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLinesSalesFullVO2
   */
  public XxcsoQuoteLinesSalesFullVOImpl getXxcsoQuoteLinesSalesFullVO2()
  {
    return (XxcsoQuoteLinesSalesFullVOImpl)findViewObject("XxcsoQuoteLinesSalesFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineSalesVL1
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineSalesVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineSalesVL1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineSalesVL2
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineSalesVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineSalesVL2");
  }



  /**
   * 
   * Container's getter for XxcsoReferenceQuoteVO1
   */
  public XxcsoReferenceQuoteVOImpl getXxcsoReferenceQuoteVO1()
  {
    return (XxcsoReferenceQuoteVOImpl)findViewObject("XxcsoReferenceQuoteVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteTypeLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteStatusLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteStatusLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteStatusLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSalesInitVO1
   */
  public XxcsoQuoteSalesInitVOImpl getXxcsoQuoteSalesInitVO1()
  {
    return (XxcsoQuoteSalesInitVOImpl)findViewObject("XxcsoQuoteSalesInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCsvDownVO1
   */
  public XxcsoCsvDownVOImpl getXxcsoCsvDownVO1()
  {
    return (XxcsoCsvDownVOImpl)findViewObject("XxcsoCsvDownVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCsvQueryVO1
   */
  public XxcsoCsvQueryVOImpl getXxcsoCsvQueryVO1()
  {
    return (XxcsoCsvQueryVOImpl)findViewObject("XxcsoCsvQueryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAccountTypeVO1
   */
  public XxcsoAccountTypeVOImpl getXxcsoAccountTypeVO1()
  {
    return (XxcsoAccountTypeVOImpl)findViewObject("XxcsoAccountTypeVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQtApTaxRateVO1
   */
  public XxcsoQtApTaxRateVOImpl getXxcsoQtApTaxRateVO1()
  {
    return (XxcsoQtApTaxRateVOImpl)findViewObject("XxcsoQtApTaxRateVO1");
  }







}