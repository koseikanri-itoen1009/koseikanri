/*============================================================================
* ファイル名 : XxcsoQuoteStoreRegistAMImpl
* 概要説明   : 帳合問屋用見積入力画面アプリケーション・モジュールクラス
* バージョン : 1.12
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領  新規作成
* 2009-02-23 1.1  SCS及川領  [CT1-004]マージン額の桁数を12⇒13桁に修正
*                            マージン率はｰ100より小さい場合はｰ99.99%、100%より
*                            大きい場合は、99.99%を固定値として表示していること
* 2009-03-24 1.2  SCS阿部大輔  【課題77】チェックの期間をプロファイル値に修正
* 2009-03-24 1.2  SCS阿部大輔  【T1_0138】ボタン制御を修正
* 2009-04-13 1.3  SCS阿部大輔  【T1_0299】CSV出力制御
* 2009-04-14 1.4  SCS阿部大輔  【T1_0461】見積書印刷制御
* 2009-05-18 1.5  SCS阿部大輔  【T1_1023】見積明細の原価割れチェックを修正
* 2009-06-16 1.6  SCS阿部大輔  【T1_1257】マージン額の変更修正
* 2009-07-23 1.7  SCS阿部大輔  【0000806】マージン額／マージン率の計算対象変更
* 2009-09-10 1.8  SCS阿部大輔  【0001331】マージン額の計算時にページ遷移を指定
* 2009-12-21 1.9  SCS阿部大輔  【E_本稼動_00535】営業原価対応
* 2011-04-18 1.10 SCS吉元強樹  【E_本稼動_01373】通常NET価格自動導出対応
* 2011-05-17 1.11 SCS桐生和幸  【E_本稼動_02500】原価割れチェック方法の変更対応
* 2011-11-14 1.12 SCSK桐生和幸 【E_本稼動_08312】問屋見積画面の改修①
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.BlobDomain;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso017002j.util.XxcsoQuoteConstants;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;

/*******************************************************************************
 * 帳合問屋用見積入力画面のアプリケーション・モジュールクラス
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteStoreRegistAMImpl()
  {
  }

  /*****************************************************************************
   * 実行区分「なし」の場合の初期化処理
   * @param quoteHeaderId          見積ヘッダーID
   * @param referenceQuoteHeaderId 参照用見積ヘッダーID
   * @param tranDiv                実行区分
   *****************************************************************************
   */
  public void initDetails(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // トランザクションを初期化
    rollback();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");
    }

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    initVo.executeQuery();

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    headerVo.initQuery(quoteHeaderId);

    headerVo.first();

    if (quoteHeaderId == null || "".equals(quoteHeaderId.trim()))
    {

      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

      headerVo.insertRow(headerRow);

      // ボタンレンダリング処理
      initRender();
      
      // 初期値設定
      headerRow.setPublishDate(
        initRow.getCurrentDate()
      );
      headerRow.setQuoteType(
        XxcsoQuoteConstants.QUOTE_STORE
      );
      headerRow.setDelivPlace(
        XxcsoQuoteConstants.DEF_DELIV_PLACE
      );
      headerRow.setPaymentCondition(
        XxcsoQuoteConstants.DEF_PAYMENT_CONDITION
      );
      headerRow.setStatus(
        XxcsoQuoteConstants.QUOTE_INPUT
      );
      headerRow.setUnitType(
        XxcsoQuoteConstants.DEF_UNIT_TYPE
      );
      headerRow.setDelivPriceTaxType(
        XxcsoQuoteConstants.DEF_DELIV_PRICE_TAX_TYPE
      );
      headerRow.setBaseCode(
        initRow.getWorkBaseCode()
      );
      headerRow.setBaseName(
        initRow.getWorkBaseName()
      );
      headerRow.setEmployeeNumber(
        initRow.getEmployeeNumber()
      );
      headerRow.setFullName(
        initRow.getFullName()
      );
      // 販売用見積画面から遷移してきた場合
      if ( referenceQuoteHeaderId != null )
      {
        headerRow.setReferenceQuoteHeaderId(
          new Number(Integer.parseInt(referenceQuoteHeaderId))
        );
      }
    }
    else
    {
      // ボタンレンダリング処理
      initRender();

      // 見積明細
      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 実行区分「COPY」の場合の初期化処理
   * @param quoteHeaderId          見積ヘッダーID
   * @param referenceQuoteHeaderId 参照用見積ヘッダーID
   * @param tranDiv                実行区分
   *****************************************************************************
   */
  public void initDetailsCopy(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
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

    // XxcsoQuoteHeaderStoreSumVO1インスタンスの取得
    XxcsoQuoteHeaderStoreSumVOImpl headerVo2 = getXxcsoQuoteHeaderStoreSumVO1();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeaderStoreSumVO1");
    }

    // XxcsoQuoteLinesStoreFullVO1インスタンスの取得
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // XxcsoQuoteLineStoreSumVO1インスタンスの取得
    XxcsoQuoteLineStoreSumVOImpl lineVo2 = getXxcsoQuoteLineStoreSumVO1();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLineStoreSumVO1");
    }

    // XxcsoQuoteStoreInitVO1インスタンスの取得
    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");      
    }

    // 初期化
    headerVo.initQuery((String)null);
    // カーソルを先頭にする
    headerVo.first();
    lineVo.first();
        
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);

    // 検索
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeaderStoreSumVORowImpl headerRow2
      = (XxcsoQuoteHeaderStoreSumVORowImpl)headerVo2.first();

    // 初期化用VOの検索
    initVo.executeQuery();
    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    // コピー
    headerRow.setReferenceQuoteNumber(
      headerRow2.getReferenceQuoteNumber()
    );
    headerRow.setReferenceQuoteHeaderIdNoBuild(
      headerRow2.getReferenceQuoteHeaderId()
    );
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setStoreName(
      headerRow2.getStoreName()
    );
    headerRow.setPublishDate(         
      initRow.getCurrentDate()          
    );
    headerRow.setAccountNumber(       
      headerRow2.getAccountNumber()      
    );
    headerRow.setPartyName(
      headerRow2.getPartyName()
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
    headerRow.setSalesUnitType(            
      headerRow2.getSalesUnitType()          
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

    // 明細のコピー
    XxcsoQuoteLineStoreSumVORowImpl lineRow2
      = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.first();

    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.createRow();

      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);
      
      // コピー
      if( "Y".equals(lineRow2.getSelectFlag()) )
      {
        lineRow.setQuoteLineId(
          lineRow2.getReferenceQuoteLineId()
        );
      }

      lineRow.setInventoryItemId(        
        lineRow2.getInventoryItemId()        
      );
      lineRow.setInventoryItemCode(      
        lineRow2.getInventoryItemCode()      
      );
      lineRow.setItemShortName(      
        lineRow2.getItemShortName()      
      );
      lineRow.setQuoteDiv(               
        lineRow2.getQuoteDiv()               
      );
      /* 20090616_abe_T1_1257 START*/
      lineRow.setBowlIncNum(
        lineRow2.getBowlIncNum()
      );
      lineRow.setCaseIncNum(
        lineRow2.getCaseIncNum()
      );
      /* 20090616_abe_T1_1257 END*/
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
      lineRow.setQuotationPrice(                
        lineRow2.getQuotationPrice()                
      );
      lineRow.setSalesDiscountPrice(                
        lineRow2.getSalesDiscountPrice()                
      );
      lineRow.setUsuallNetPrice(                
        lineRow2.getUsuallNetPrice()                
      );
      lineRow.setThisTimeNetPrice(                
        lineRow2.getThisTimeNetPrice()                
      );
      lineRow.setAmountOfMargin(                
        lineRow2.getAmountOfMargin()                
      );
      lineRow.setMarginRate(                
        lineRow2.getMarginRate()                
      );
      lineRow.setQuoteEndDate(
        lineRow2.getQuoteEndDate()
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
      lineRow.setSelectFlag(
        lineRow2.getSelectFlag()
      );

      // コピーした後に初期化
      lineRow.setQuoteStartDate(initRow.getCurrentDate());

      lineRow2 = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.next();
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
   * @param quoteHeaderId          見積ヘッダーID
   * @param referenceQuoteHeaderId 参照用見積ヘッダーID
   * @param tranDiv                実行区分
   *****************************************************************************
   */
  public void initDetailsRevisionUp(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
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

    // XxcsoQuoteHeaderStoreSumVO1インスタンスの取得
    XxcsoQuoteHeaderStoreSumVOImpl headerVo2 = getXxcsoQuoteHeaderStoreSumVO1();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeaderStoreSumVO1");
    }

    // XxcsoQuoteLinesStoreFullVO1インスタンスの取得
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // XxcsoQuoteLineStoreSumVO1インスタンスの取得
    XxcsoQuoteLineStoreSumVOImpl lineVo2 = getXxcsoQuoteLineStoreSumVO1();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLineStoreSumVO1");
    }

    // XxcsoQuoteStoreInitVO1インスタンスの取得
    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");      
    }

    // 初期化
    headerVo.initQuery((String)null);
    // カーソルを先頭にする
    headerVo.first();
    lineVo.first();
        
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);

    // 検索
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeaderStoreSumVORowImpl headerRow2
      = (XxcsoQuoteHeaderStoreSumVORowImpl)headerVo2.first();

    // 初期化用VOの検索
    initVo.executeQuery();
    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    // 属性数を取得
    int attrNum = headerVo.getAttributeCount();

     // コピー
    headerRow.setReferenceQuoteNumber(
      headerRow2.getReferenceQuoteNumber()
    );
    headerRow.setReferenceQuoteHeaderIdNoBuild(
      headerRow2.getReferenceQuoteHeaderId()
    );
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setStoreName(
      headerRow2.getStoreName()
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
    headerRow.setPartyName(
      headerRow2.getPartyName()
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
    headerRow.setSalesUnitType(            
      headerRow2.getSalesUnitType()          
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

    // 改訂元のステータスを旧版にする
    headerRow2.setStatus(XxcsoQuoteConstants.QUOTE_OLD);
    
    // 明細のコピー
    XxcsoQuoteLineStoreSumVORowImpl lineRow2
      = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.first();
    
    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.createRow();
      
      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);

      // コピー
      if( "Y".equals(lineRow2.getSelectFlag()) )
      {
        lineRow.setQuoteLineId(
          lineRow2.getReferenceQuoteLineId()
        );
      }
      lineRow.setInventoryItemId(        
        lineRow2.getInventoryItemId()        
      );
      lineRow.setInventoryItemCode(      
        lineRow2.getInventoryItemCode()      
      );
      lineRow.setItemShortName(      
        lineRow2.getItemShortName()      
      );
      lineRow.setQuoteDiv(               
        lineRow2.getQuoteDiv()               
      );
      /* 20090616_abe_T1_1257 START*/
      lineRow.setBowlIncNum(
        lineRow2.getBowlIncNum()
      );
      lineRow.setCaseIncNum(
        lineRow2.getCaseIncNum()
      );
      /* 20090616_abe_T1_1257 END*/

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
      lineRow.setQuotationPrice(                
        lineRow2.getQuotationPrice()                
      );
      lineRow.setSalesDiscountPrice(                
        lineRow2.getSalesDiscountPrice()                
      );
      lineRow.setUsuallNetPrice(                
        lineRow2.getUsuallNetPrice()                
      );
      lineRow.setThisTimeNetPrice(                
        lineRow2.getThisTimeNetPrice()                
      );
      lineRow.setAmountOfMargin(                
        lineRow2.getAmountOfMargin()                
      );
      lineRow.setMarginRate(                
        lineRow2.getMarginRate()                
      );
      lineRow.setQuoteEndDate(
        lineRow2.getQuoteEndDate()
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
      lineRow.setSelectFlag(
        lineRow2.getSelectFlag()
      );

      // コピーした後に初期化
      lineRow.setQuoteStartDate(initRow.getCurrentDate());

      lineRow2 = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.next();
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
   * 取消ボタン押下時処理
   *****************************************************************************
   */
  public HashMap handleCancelButton(
    String referenceQuoteHeaderId,
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

    // 見積ヘッダーID
    if ( headerRow != null )
    {
      params.put(
        XxcsoConstants.TRANSACTION_KEY1,
        headerRow.getReferenceQuoteHeaderId()
      );
    }
    else
    {
      params.put(
        XxcsoConstants.TRANSACTION_KEY1,
        referenceQuoteHeaderId
      );
    }

    // 実行区分
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_UPDATE
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 

  }

  /*****************************************************************************
   * コピーの作成ボタン押下時処理
   * @return HashMap     URLパラメータ
   * @param returnPgName 戻り先画面名称
   *****************************************************************************
   */
  public HashMap handleCopyCreateButton(
    String referenceQuoteHeaderId,
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

   // 見積ヘッダーID
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
   * @param returnPgName 戻り先画面名称
   *****************************************************************************
   */
  public HashMap handleApplicableButton(
    String referenceQuoteHeaderId,
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
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

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // 入力チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    // 見積ヘッダー
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    // 見積明細
    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    // 参照用見積番号
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getReferenceQuoteNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REFERENCE_QUOTE_NUMBER
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

    int index = 0;
    
    while ( lineRow != null )
    {
      index++;

      if( "Y".equals(lineRow.getSelectFlag()) )
      {
/* 20090616_abe_T1_1257 START*/
        handleMarginCalculation(
          lineRow.getQuoteLineId().toString()
        );
/* 20090616_abe_T1_1257 END*/

        //DB反映チェック      
        errorList
          = validateLine(
              errorList
             ,lineRow
             ,index
            );
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

/* 20090910_abe_0001331 START*/
    lineVo.first();
/* 20090910_abe_0001331 END*/

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
   * @param returnPgName 戻り先画面名称
   *****************************************************************************
   */
  public HashMap handleRevisionButton(
    String referenceQuoteHeaderId,
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

    // 見積ヘッダーID
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

    // 販売用見積画面から遷移してきた場合は販売用もステータスを更新する
    handleupdatesales();

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
      /* 20090414_abe_T1_0461 START*/
      //if ( getTransaction().isDirty() )
      //{
      /* 20090414_abe_T1_0461 END*/
        // 画面項目の入力チェック
        validateFixed();

        // 保存処理を実行します。
        commit();
      /* 20090414_abe_T1_0461 START*/
      //}
      /* 20090414_abe_T1_0461 END*/
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
      sql.append("        ,program           => 'XXCSO017A04C'");
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
            + XxcsoConstants.TOKEN_VALUE_REQUEST_ID
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
   * @return OAException 正常終了メッセージ
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
      /* 20090414_abe_T1_0461 START*/
      //if ( getTransaction().isDirty() )
      //{
      /* 20090414_abe_T1_0461 END*/
        // 画面項目の入力チェック
        validateFixed();

        // 保存処理を実行します。
        commit();
      /* 20090414_abe_T1_0461 START*/
      //}
      /* 20090414_abe_T1_0461 END*/
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
        // 項目:通常店頭売価
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:今回店納価格
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:今回店頭売価
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
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
        // 項目:担当者コード（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:担当者名（帳合用）
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
        // 項目:見積情報期間（開始）（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積情報期間（終了）（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積書提出先名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:ステータス（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:販売先単価区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:問屋単価区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:税区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:特記事項（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:商品コード（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:商品名（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:見積区分（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:通常店納価格（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // 項目:今回店納価格（帳合用）
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
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
   * 参照用見積番号項目の制御処理
   *****************************************************************************
   */
  public void setAttributeProperty()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteStoreInitVOImpl initVo
      = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteStoreInitVO1"
        );
    }
    
    XxcsoQuoteHeadersFullVOImpl headerVo
      = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeadersFullVO1"
        );
    }

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( headerRow != null )
    {
      if ( headerRow.getReferenceQuoteHeaderId() != null )
      {
        initRow.setRefQuoteNumberRender(Boolean.FALSE);
        initRow.setRefQuoteNumberViewRender(Boolean.TRUE);
      }
      else
      {
        initRow.setRefQuoteNumberRender(Boolean.TRUE);
        initRow.setRefQuoteNumberViewRender(Boolean.FALSE);
      }
    }
    else
    {
        initRow.setRefQuoteNumberRender(Boolean.TRUE);
        initRow.setRefQuoteNumberViewRender(Boolean.FALSE);      
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 税区分項目の制御処理
   * @param quoteHeaderId          見積ヘッダーID
   * @param referenceQuoteHeaderId 参照用見積ヘッダーID
   * @param tranDiv                実行区分
   *****************************************************************************
   */
  public void setAttributeTaxType(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteStoreInitVOImpl initVo
      = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteStoreInitVO1"
        );
    }
    
    XxcsoQuoteHeadersFullVOImpl headerVo
      = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeadersFullVO1"
        );
    }

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.TRANDIV_UPDATE.equals(tranDiv) ||
      XxcsoQuoteConstants.TRANDIV_CREATE.equals(tranDiv) )
    {
      initRow.setDelivPriceTaxTypeRender(Boolean.FALSE);
      initRow.setDelivPriceTaxTypeViewRender(Boolean.TRUE);
    }
    else
    {
      initRow.setDelivPriceTaxTypeRender(Boolean.TRUE);
      initRow.setDelivPriceTaxTypeViewRender(Boolean.FALSE);
    }
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

    // *****販売先単価区分
    XxcsoLookupListVOImpl unitPriceSalesLookupVo
        = getXxcsoUnitPriceSalesLookupVO();

    if (unitPriceSalesLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoUnitPriceSalesLookupVO");
    }
    // lookupの初期化
    unitPriceSalesLookupVo.initQuery("XXCSO1_UNIT_PRICE_DIVISION", "1");

    // *****税区分
    XxcsoLookupListVOImpl delivPriceTaxTypeLookupVo =
      getXxcsoDelivPriceTaxTypeLookupVO();
    if (delivPriceTaxTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDelivPriceTaxDivLookupVO");
    }
    // lookupの初期化
    delivPriceTaxTypeLookupVo.initQuery("XXCSO1_TAX_DIVISION", "1");
      
    // *****問屋単価区分
    XxcsoLookupListVOImpl unitPriceStoreLookupVo
        = getXxcsoUnitPriceStoreLookupVO();

    if (unitPriceStoreLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoUnitPriceStoreLookupVO");
    }
    // lookupの初期化
    unitPriceStoreLookupVo.initQuery("XXCSO1_UNIT_PRICE_DIVISION", "1");

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
   * マージン算出を行う処理
   * @param quoteLineId 見積明細ID
   *****************************************************************************
   */
  public void handleMarginCalculation(
    String quoteLineId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    /* 20090616_abe_T1_1257 START*/
    // XxcsoQuoteHeadersFullVO1インスタンスの取得
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    /* 20090616_abe_T1_1257 END*/


    // XxcsoQuoteLinesStoreFullVO1インスタンスの取得
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( quoteLineId.equals(lineRow.getQuoteLineId().stringValue()) )
      {

        // 算出用ワークの初期値
        String netPrice = XxcsoQuoteConstants.DEF_PRICE;
        BigDecimal defRate = new BigDecimal(XxcsoQuoteConstants.DEF_RATE);

/* 20090723_abe_0000806 START*/
        //// 見積区分が「1」の場合は、通常価格で算出。それ以外は今回価格で算出します。
        //if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
        //       lineRow.getQuoteDiv())
        //   )
        //{
        // 今回店納価格が設定なしの場合は、通常価格で算出。それ以外は今回価格で算出します。
        if ( lineRow.getThisTimeDelivPrice() == null )
        {
/* 20090723_abe_0000806 END*/
          // マージン額を算出
          if ( lineRow.getUsuallNetPrice() == null )
          {
            netPrice = XxcsoQuoteConstants.DEF_PRICE;
          }
          else
          {
            netPrice = lineRow.getUsuallNetPrice();
          }

          try
          {
            // 計算
            BigDecimal Price1
              = new BigDecimal(
                lineRow.getUsuallyDelivPrice().replaceAll(",","")
              );
            BigDecimal Price2 = new BigDecimal(netPrice.replaceAll(",",""));
            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceSubtract = Price1.subtract(Price2);
            BigDecimal PriceSalesSubtract;
            BigDecimal PriceStoreSubtract;
            BigDecimal PriceSubtract = BigDecimal.valueOf(0);

            BigDecimal DecCase_num = BigDecimal.valueOf(0);
            BigDecimal DecBowl_num = BigDecimal.valueOf(0);
            
            //入数チェック(販売単価区分)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getSalesUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0)== 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getSalesUnitType())))
              )
            {
              PriceSalesSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //販売単価区分が本数の場合
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getSalesUnitType()))
              {
                PriceSalesSubtract = Price1;
              }
              //販売単価区分がC/Sの場合
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getSalesUnitType()))
              {
                DecCase_num = 
                   lineRow.getCaseIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //販売単価区分がボールの場合
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }
            //入数チェック(問屋単価区分)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0)== 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getUnitType())))
              )
            {
              PriceStoreSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //単価区分が本数の場合
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getUnitType()))
              {
                PriceStoreSubtract = Price2;
              }
              //単価区分がC/Sの場合
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getUnitType()))
              {
                DecCase_num = 
                  lineRow.getCaseIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //単価区分がボールの場合
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }

            //マージ額計算
            PriceSubtract = PriceSalesSubtract.subtract(PriceStoreSubtract);
            /* 20090616_abe_T1_1257 END*/

            // マージン額に計算結果を反映します。
            lineRow.setAmountOfMargin(String.valueOf(PriceSubtract));

            // マージン率を算出
            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceDivide = PriceSubtract.divide(
            //  Price1,6,BigDecimal.ROUND_HALF_UP);
            BigDecimal PriceDivide = BigDecimal.valueOf(0);
            if (PriceSalesSubtract.doubleValue() != 0)
            {
              PriceDivide = PriceSubtract.divide(
                PriceSalesSubtract,6,BigDecimal.ROUND_HALF_UP);
            }
            /* 20090616_abe_T1_1257 END*/

            BigDecimal PriceMultiply = PriceDivide.multiply(defRate);

            BigDecimal PriceScale 
              = PriceMultiply.setScale(2, BigDecimal.ROUND_HALF_UP);

            // マージン率に計算結果を反映します。
            BigDecimal limitMin
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MIN);
            BigDecimal limitMax
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MAX);

            // -100より小さい場合は-99.99固定とします
            if ( limitMin.compareTo(PriceScale) == 1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MIN);
            }
            // 100より大きい場合は99.99固定とします
            else if ( limitMax.compareTo(PriceScale) == -1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MAX);
            }
            else
            {
              lineRow.setMarginRate(String.valueOf(PriceScale));
            }
          }
          catch ( NumberFormatException e )
          {
            XxcsoUtils.debug(txn, "NumberFormatException");
          }
        }
        else
        {
          // マージン額を算出
          if ( lineRow.getThisTimeNetPrice() == null )
          {
            netPrice = XxcsoQuoteConstants.DEF_PRICE;
          }
          else
          {
            netPrice = lineRow.getThisTimeNetPrice();
          }
          try
          {
            // 計算
            BigDecimal Price1
              = new BigDecimal(
                lineRow.getThisTimeDelivPrice().replaceAll(",","")
              );
            BigDecimal Price2 = new BigDecimal(netPrice.replaceAll(",",""));

            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceSubtract = Price1.subtract(Price2);
            BigDecimal PriceSalesSubtract;
            BigDecimal PriceStoreSubtract;
            BigDecimal PriceSubtract = BigDecimal.valueOf(0);

            BigDecimal DecCase_num = BigDecimal.valueOf(0);
            BigDecimal DecBowl_num = BigDecimal.valueOf(0);
            
            //入数チェック(販売単価区分)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getSalesUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getSalesUnitType())))
              )
            {
              PriceSalesSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //販売単価区分が本数の場合
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getSalesUnitType()))
              {
                PriceSalesSubtract = Price1;
              }
              //販売単価区分がC/Sの場合
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getSalesUnitType()))
              {
                DecCase_num = 
                   lineRow.getCaseIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //販売単価区分がボールの場合
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }
            //入数チェック(問屋単価区分)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getUnitType())))
              )
            {
              PriceStoreSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //単価区分が本数の場合
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getUnitType()))
              {
                PriceStoreSubtract = Price2;
              }
              //単価区分がC/Sの場合
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getUnitType()))
              {
                DecCase_num = 
                   lineRow.getCaseIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //単価区分がボールの場合
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }
            //マージ額計算
            PriceSubtract = PriceSalesSubtract.subtract(PriceStoreSubtract);
            /* 20090616_abe_T1_1257 END*/

            // マージン額に計算結果を反映します。
            lineRow.setAmountOfMargin(String.valueOf(PriceSubtract));

            // マージン率を算出
            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceDivide = PriceSubtract.divide(
            //  Price1,6,BigDecimal.ROUND_HALF_UP);
            BigDecimal PriceDivide = BigDecimal.valueOf(0);
            if (PriceSalesSubtract.doubleValue() != 0)
            {
              PriceDivide = PriceSubtract.divide(
                PriceSalesSubtract,6,BigDecimal.ROUND_HALF_UP);
            }
            /* 20090616_abe_T1_1257 END*/

            BigDecimal PriceMultiply = PriceDivide.multiply(defRate);

            BigDecimal PriceScale 
              = PriceMultiply.setScale(2, BigDecimal.ROUND_HALF_UP);

            // マージン率に計算結果を反映します。
            BigDecimal limitMin
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MIN);
            BigDecimal limitMax
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MAX);

            // -100より小さい場合は-99.99固定とします
            if ( limitMin.compareTo(PriceScale) == 1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MIN);
            }
            // 100より大きい場合は99.99固定とします
            else if ( limitMax.compareTo(PriceScale) == -1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MAX);
            }
            else
            {
              lineRow.setMarginRate(String.valueOf(PriceScale));
            }
          }
          catch ( NumberFormatException e )
          {
            XxcsoUtils.debug(txn, "NumberFormatException");
          }
        }
        break;
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }
/* 20090616_abe_T1_1257 START*/
    //lineVo.first();
/* 20090616_abe_T1_1257 END*/
/* 20090910_abe_0001331 START*/
    try{
      BigDecimal line_row = new BigDecimal(lineVo.getCurrentRowIndex()+1);
      BigDecimal line_size =new BigDecimal(
                    txn.getProfile("XXCSO1_VIEW_SIZE_017_A02_01".toString()));

      line_row = line_row.divide(line_size,0,BigDecimal.ROUND_UP);
      lineVo.scrollToRangePage((line_row.intValue()));
    }
    catch ( NumberFormatException e )
    {
      lineVo.first();
    }
/* 20090910_abe_0001331 END*/


    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 建値の算出処理
   *****************************************************************************
   */
  public void handleValidateReference()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    XxcsoReferenceQuotationPriceVOImpl refVo 
      = getXxcsoReferenceQuotationPriceVO1();
    if ( refVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoReferenceQuotationPriceVO1");
    }

      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      // 参照対象のデータが存在しているかを確認
      refVo.initQuery(lineRow.getInventoryItemId().toString()
                     ,headerRow.getAccountNumber());

      XxcsoReferenceQuotationPriceVORowImpl refRow
        = (XxcsoReferenceQuotationPriceVORowImpl)refVo.first();

      if ( refRow != null )
      {
        if ( lineRow.getQuotationPrice() == null &&
             refRow.getQuotationPrice() != null )
        {
          //検索結果がある場合は建値を設定する
          lineRow.setQuotationPrice(refRow.getQuotationPrice().toString());
        }
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    lineVo.first();

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * 販売用見積のステータス更新処理
   * @see xxcso_017002j_pkg.set_sales_status
   *****************************************************************************
   */
  public void handleupdatesales()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    OracleCallableStatement stmt = null;

    //ステータス更新用プロシージャをcall
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append(" xxcso_017002j_pkg.set_sales_status(");
      sql.append(" :1);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
      // パラメータの設定
      stmt.setNUMBER(1, headerRow.getReferenceQuoteHeaderId());
      
      XxcsoUtils.debug(
        txn, "ReferenceQuoteHeaderId:"+headerRow.getReferenceQuoteHeaderId());

        XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_REGIST
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
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * 見積情報（帳合用）構築処理
   * XxcsoQuoteHeadersFullVORowImpl.setReferenceQuoteHeaderIdよりCallされます。
   * @param referenceQuoteHeaderId 見積ヘッダーID（販売先用）
   * @see itoen.oracle.apps.xxcso.xxcso017002j.server.XxcsoQuoteHeadersFullVORowImpl.setReferenceQuoteHeaderId()
   *****************************************************************************
   */
  protected void buildQuoteStore(
    Number referenceQuoteHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo
      = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeadersFullVO1"
        );
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo
      = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteLinesStoreFullVO1"
        );
    }

    XxcsoQuoteHeaderSalesSumVOImpl salesHeaderVo
      = getXxcsoQuoteHeaderSalesSumVO1();
    if ( salesHeaderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeaderSalesSumVO1"
        );
    }

    XxcsoQuoteLineSalesSumVOImpl salesLineVo
      = getXxcsoQuoteLineSalesSumVO1();
    if ( salesLineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteLineSalesSumVO1"
        );
    }

    salesHeaderVo.initQuery(referenceQuoteHeaderId);

    XxcsoQuoteHeaderSalesSumVORowImpl salesHeaderRow
      = (XxcsoQuoteHeaderSalesSumVORowImpl)salesHeaderVo.first();
    if ( salesHeaderRow == null )
    {
      return;
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    headerRow.setStoreName(salesHeaderRow.getStoreName());
    headerRow.setSalesUnitType(salesHeaderRow.getUnitType());
    headerRow.setReferenceQuoteNumber(salesHeaderRow.getQuoteNumber());
    
    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();
    while ( lineRow != null )
    {
      lineVo.removeCurrentRow();
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    salesLineVo.initQuery(referenceQuoteHeaderId);
    XxcsoQuoteLineSalesSumVORowImpl salesLineRow
      = (XxcsoQuoteLineSalesSumVORowImpl)salesLineVo.first();

    while ( salesLineRow != null )
    {
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.createRow();

      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);

      lineRow.setQuoteLineId(salesLineRow.getQuoteLineId());
      lineRow.setInventoryItemId(salesLineRow.getInventoryItemId());
      lineRow.setInventoryItemCode(salesLineRow.getInventoryItemCode());
      lineRow.setItemShortName(salesLineRow.getItemShortName());
      lineRow.setQuoteDiv(salesLineRow.getQuoteDiv());
/* 20090616_abe_T1_1257 START*/
      lineRow.setCaseIncNum(salesLineRow.getCaseIncNum());
      lineRow.setBowlIncNum(salesLineRow.getBowlIncNum());
/* 20090616_abe_T1_1257 END*/
      lineRow.setUsuallyDelivPrice(salesLineRow.getUsuallyDelivPrice());
      lineRow.setThisTimeDelivPrice(salesLineRow.getThisTimeDelivPrice());
      lineRow.setQuoteStartDate(salesLineRow.getQuoteStartDate());
      lineRow.setQuoteEndDate(salesLineRow.getQuoteEndDate());
      lineRow.setSelectFlag("N");

      salesLineRow = (XxcsoQuoteLineSalesSumVORowImpl)salesLineVo.next();
    }

    lineVo.first();
    
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
    
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
    XxcsoQtApTaxRateVOImpl taxVo = getXxcsoQtApTaxRateVO1();
    if ( taxVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQtApTaxRateVO1");
    }
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End

    errorList = validateHeader(errorList);

    /* 20090518_abe_T1_1023 START*/
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    /* 20090518_abe_T1_1023 END*/

    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
    XxcsoQtApTaxRateVORowImpl taxRow
      = (XxcsoQtApTaxRateVORowImpl)taxVo.first();
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End

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
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add Start
    //プロファイル(XXCSO:異常マージン率)の取得
    String err_Margin_Rate_Str = txn.getProfile(XxcsoQuoteConstants.ERR_MARGIN_RATE);
    double err_Margin_Rate = 0;
    if ( err_Margin_Rate_Str == null || "".equals(err_Margin_Rate_Str.trim()) )
    {
      //取得できない(NULL)場合エラーを表示し終了
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoQuoteConstants.ERR_MARGIN_RATE
        );
    }
    try{
      err_Margin_Rate = Double.parseDouble(err_Margin_Rate_Str);
    }
    catch ( NumberFormatException e )
    {
      //数値に変換できない場合エラーを表示し終了
      throw
        XxcsoMessage.createProfileOptionValueError(
          XxcsoQuoteConstants.ERR_MARGIN_RATE
         ,err_Margin_Rate_Str
        );
    }
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add End
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
    //仮払税率の存在チェック
    double taxrate = -1;
    if ( taxRow != null )
    {
      taxrate = taxRow.getApTaxRate().doubleValue();
    }
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End
    int index = 0;
    while ( lineRow != null )
    {
      if( "Y".equals(lineRow.getSelectFlag()) )
      {
        index++;
// 2011-11-14 Ver1.12 [E_本稼動_08312] Del Start
///* 20090616_abe_T1_1257 START*/
//        handleMarginCalculation(
//          lineRow.getQuoteLineId().toString()
//        );
///* 20090616_abe_T1_1257 END*/
// 2011-11-14 Ver1.12 [E_本稼動_08312] Del End
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
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
         ,taxrate
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add Start
         ,err_Margin_Rate
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add End
        );
      }
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }
/* 20090910_abe_0001331 START*/
    lineVo.first();
/* 20090910_abe_0001331 END*/

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

    // 参照用見積番号
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getReferenceQuoteNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REFERENCE_QUOTE_NUMBER
         ,0
        );

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
   ,XxcsoQuoteLinesStoreFullVORowImpl lineRow
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
    //if ( lineRow.getQuotationPrice() == null )
    //{
    //  lineRow.setQuotationPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getSalesDiscountPrice() == null )
    //{
    //  lineRow.setSalesDiscountPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getUsuallNetPrice() == null )
    //{
    //  lineRow.setUsuallNetPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getThisTimeNetPrice() == null )
    //{
    //  lineRow.setThisTimeNetPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}
/* 20090723_abe_0000806 END*/

    // 建値
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getQuotationPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTATION_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 売上値引
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getSalesDiscountPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_SALES_DISCOUNT_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 通常NET価格
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getUsuallNetPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 今回NET価格
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getThisTimeNetPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE
         ,2
         ,5
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
   * @param errorList        エラーリスト
   * @param headerRow        見積ヘッダ行インスタンス
   * @param lineRow          見積明細行インスタンス
   * @param index            対象行
   * @param period_Daye      プロファイル値←20090324_abe_課題77 ADD
   * @param taxrate          税率
   * @param err_Margin_Rate  異常マージン率
   *****************************************************************************
   */
  private List validateFixedLine(
    List                              errorList
   /* 20090518_abe_T1_1023 START*/
   ,XxcsoQuoteHeadersFullVORowImpl  headerRow
   /* 20090518_abe_T1_1023 END*/
   ,XxcsoQuoteLinesStoreFullVORowImpl lineRow
   ,int                               index
   /* 20090324_abe_課題77 START*/
   ,int                               period_Daye
   /* 20090324_abe_課題77 END*/
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
   ,double                            taxrate
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add Start
   ,double                            err_Margin_Rate
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add End
  )
  {
    OADBTransaction txn = getOADBTransaction();
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
    double taxratecul = 0;
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End
    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");      
    }

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

// 2011-11-14 Ver1.12 [E_本稼動_08312] Add Start
    //マージン率の計算   
    handleMarginCalculation(
      lineRow.getQuoteLineId().toString()
    );
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add End

    // 必須チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

/* 2009.07.30 D.Abe 0000806対応 START */
    // 建値
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuotationPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTATION_PRICE
         ,index
        );
/* 2009.07.30 D.Abe 0000806対応 END */

    // 期間（開始）
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuoteStartDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_START_DATE
         ,index
        );

    // 期間チェック
    if ( lineRow.getQuoteStartDate() != null )
    {
      Date currentDate = new Date(initRow.getCurrentDate());
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

      // 期間（開始）が期間（終了）より未来ではないかチェック
      if ( lineRow.getQuoteEndDate().compareTo(
                                         lineRow.getQuoteStartDate()) < 0
           )
      {
        XxcsoUtils.debug(txn, limitDate);

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00499
             ,XxcsoConstants.TOKEN_INDEX
             ,String.valueOf(index)
            );
        errorList.add(error);
      }
    }
    
/* 20090616_abe_T1_1257 START*/
/* 20090723_abe_0000806 START*/
    // 入数のチェック
    //double caseincnum      = lineRow.getCaseIncNum().doubleValue();
    //double bowlincnum      = lineRow.getBowlIncNum().doubleValue();

    //if(((caseincnum == 0) &&
    //    (headerRow.getUnitType().equals("2"))) ||
    //   ((bowlincnum == 0) &&
    //    (headerRow.getUnitType().equals("3")))
    //  )
    //{
    //    OAException error
    //      = XxcsoMessage.createErrorMessage(
    //          XxcsoConstants.APP_XXCSO1_00574,
    //          XxcsoConstants.TOKEN_INDEX,
    //          String.valueOf(index)
    //        );
    //    errorList.add(error);
    //}
    //else
    //{
/* 20090723_abe_0000806 END*/
    // 通常か特売の場合は、NET価格の原価割れチェック
    if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(lineRow.getQuoteDiv()) ||
       XxcsoQuoteConstants.QUOTE_DIV_BARGAIN.equals(lineRow.getQuoteDiv())
       )
    {
/* 20090723_abe_0000806 START*/
      // 通常NET価格の必須チェック
      if(lineRow.getUsuallNetPrice() == null) 
      {
        errorList
          = util.requiredCheck(
              errorList
             ,lineRow.getUsuallNetPrice()
             ,XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE
             ,index
            );
      }
      else
      {
        // 入数のチェック
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
        else
        {
/* 20090723_abe_0000806 END*/
          String usuallNetPriceRep 
            = lineRow.getUsuallNetPrice().replaceAll(",", "");
/* 20090723_abe_0000806 START*/
          //String thisTimeNetPriceRep 
          //  = lineRow.getThisTimeNetPrice().replaceAll(",", "");
/* 20090723_abe_0000806 END*/
          /* 20090518_abe_T1_1023 START*/
          String unittype        = headerRow.getUnitType();
          //double caseincnum      = lineRow.getCaseIncNum().doubleValue();
          //double bowlincnum      = lineRow.getBowlIncNum().doubleValue();
          /* 20090518_abe_T1_1023 END*/      
/* 20090616_abe_T1_1257 END*/
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
          //税区分が"2"(税込価格)の場合、仮払税率のチェック
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
                    XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
          }
          //税区分が"1"(税抜価格)の場合
          else
          {
            //営業原価でチェックする為、税率に1を設定
            taxratecul = 1;
          }
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod Start
//          /* 20091221_abe_E_本稼動_00535 START*/
//          if (lineRow.getBusinessPrice() != null)
          if ((lineRow.getBusinessPrice() != null) &&
              (taxrate != -1)
             )
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod End
          {
          /* 20091221_abe_E_本稼動_00535 END*/
            double businessPrice = lineRow.getBusinessPrice().doubleValue();
            try
            {
              double usuallNetPrice  = Double.parseDouble(usuallNetPriceRep);

              // 通常NET価格
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod Start
//              /* 20090518_abe_T1_1023 START*/
//              if ( (usuallNetPrice <= businessPrice && unittype.equals("1") ) ||
//                   ((usuallNetPrice / caseincnum <= businessPrice ||
//                    caseincnum == 0) && unittype.equals("2") ) || 
//                   ((usuallNetPrice / bowlincnum <= businessPrice ||
//                    bowlincnum == 0) && unittype.equals("3"))
//                 )
//              //if ( usuallNetPrice <= businessPrice )
              if ( (usuallNetPrice <= businessPrice  * taxratecul && unittype.equals("1") ) ||
                   ((usuallNetPrice / caseincnum <= businessPrice * taxratecul ||
                    caseincnum == 0) && unittype.equals("2") ) || 
                   ((usuallNetPrice / bowlincnum <= businessPrice * taxratecul ||
                    bowlincnum == 0) && unittype.equals("3"))
                 )
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod End
              /* 20090518_abe_T1_1023 END*/
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00498,
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
      // 今回店納価格が設定されている場合
      if(lineRow.getThisTimeDelivPrice() != null) 
      {
        // 今回NET価格の必須チェック
        if(lineRow.getThisTimeNetPrice() == null)
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getThisTimeNetPrice()
               ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE
               ,index
              );
        }
        else
        {
          // 入数のチェック
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
          else
          {
            String thisTimeNetPriceRep 
              = lineRow.getThisTimeNetPrice().replaceAll(",", "");
            String unittype        = headerRow.getUnitType();
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add Start
            //税率初期化
            taxratecul = 0;
            //税区分が"2"(税込価格)の場合、仮払税率のチェック
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
                      XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
            //税区分が"1"(税抜価格)の場合
            else
            {
              //営業原価でチェックする為、税率に1を設定
              taxratecul = 1;
            }
// 2011-05-17 Ver1.11 [E_本稼動_02500] Add End
            /* 20091221_abe_E_本稼動_00535 START*/
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod Start
//            if (lineRow.getBusinessPrice() != null)
            if ((lineRow.getBusinessPrice() != null) &&
                (taxrate != -1)
               )
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod End
            {
            /* 20091221_abe_E_本稼動_00535 END*/
              double businessPrice = lineRow.getBusinessPrice().doubleValue();
/* 20090723_abe_0000806 END*/
              try
              {
                double thisTimeNetPrice = Double.parseDouble(thisTimeNetPriceRep);

                // 今回NET価格
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod Start
//                /* 20090518_abe_T1_1023 START*/
//                if ( (thisTimeNetPrice <= businessPrice && unittype.equals("1") ) ||
//                     ((thisTimeNetPrice / caseincnum <= businessPrice ||
//                      caseincnum == 0) && unittype.equals("2") ) || 
//                     ((thisTimeNetPrice / bowlincnum <= businessPrice ||
//                      bowlincnum == 0) && unittype.equals("3"))
//                   )
//                //if ( thisTimeNetPrice <= businessPrice )
//                /* 20090518_abe_T1_1023 END*/
                if ( (thisTimeNetPrice <= businessPrice * taxratecul && unittype.equals("1") ) ||
                     ((thisTimeNetPrice / caseincnum <= businessPrice * taxratecul ||
                      caseincnum == 0) && unittype.equals("2") ) || 
                     ((thisTimeNetPrice / bowlincnum <= businessPrice * taxratecul ||
                      bowlincnum == 0) && unittype.equals("3"))
                   )
// 2011-05-17 Ver1.11 [E_本稼動_02500] Mod End
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00498,
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
/* 20090723_abe_0000806 START*/
          }
/* 20090723_abe_0000806 END*/
        }
/* 20090723_abe_0000806 START*/
      }
/* 20090723_abe_0000806 END*/
/* 20090616_abe_T1_1257 START*/
    }
/* 20090616_abe_T1_1257 END*/
/* 20090723_abe_0000806 START*/
    // 新規導入か原価割れの場合
    if ( XxcsoQuoteConstants.QUOTE_DIV_INTRO.equals(lineRow.getQuoteDiv()) ||
         XxcsoQuoteConstants.QUOTE_DIV_COST.equals(lineRow.getQuoteDiv())
       )
    {
      // 通常NET価格の必須チェック
      if(lineRow.getUsuallNetPrice() == null) 
      {
        errorList
          = util.requiredCheck(
              errorList
             ,lineRow.getUsuallNetPrice()
             ,XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE
             ,index
            );
      }
      // 今回店納価格が設定されている場合
      if(lineRow.getThisTimeDelivPrice() != null) 
      {
        // 今回NET価格の必須チェック
        if(lineRow.getThisTimeNetPrice() == null)
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getThisTimeNetPrice()
               ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE
               ,index
              );
        }
      }
    }
/* 20090723_abe_0000806 END*/
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add Start
    //異常マージン率以上の場合エラー
    if ( err_Margin_Rate <= Double.parseDouble(lineRow.getMarginRate()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00617
           ,XxcsoConstants.TOKEN_MARGIN_RATE
           ,String.valueOf(err_Margin_Rate)
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          );
        errorList.add(error);       
    }
// 2011-11-14 Ver1.12 [E_本稼動_08312] Add End
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

/* 20090723_abe_0000806 START*/
  /*****************************************************************************
   * 問屋明細行表示属性プロパティ設定
   *****************************************************************************
   */
  public void setLineProperty()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    XxcsoReferenceQuotationPriceVOImpl refVo 
      = getXxcsoReferenceQuotationPriceVO1();
    if ( refVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoReferenceQuotationPriceVO1");
    }

      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      // 今回店納価格が設定なしの場合、今回NET価格を使用不可
      if (lineRow.getThisTimeDelivPrice() == null)
      {
        lineRow.setThisTimeDelivReadOnly(Boolean.TRUE);
      }
      else
      {
        lineRow.setThisTimeDelivReadOnly(Boolean.FALSE);
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    lineVo.first();

    XxcsoUtils.debug(txn, "[END]");

  }

/* 20090723_abe_0000806 END*/

// 2011-04-18 v1.10 T.Yoshimoto Add Start E_本稼動_01373
  /*****************************************************************************
   * 通常NET価格取得処理
   *****************************************************************************
   */
  public void handleUsuallNetPriceButton()
  {

    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////

    // 見積ヘッダVOインスタンス取得
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // 見積明細VOインスタンス取得
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // 通常NET価格VOインスタンス取得
    XxcsoUsuallNetPriceVOImpl usuallNetPriceVo = getXxcsoUsuallNetPriceVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoUsuallNetPriceVO1");
    }

    // 見積ヘッダVOの1行目を取得
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    
    // 見積明細VOの1行目を取得
    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {

      if ( "Y".equals(lineRow.getSelectFlag()) )
      {

        // 通常NET価格の検索実行
        usuallNetPriceVo.initQuery(
          headerRow.getAccountNumber(),    // 顧客コード
          lineRow.getInventoryItemId(),    // 品目ID
          lineRow.getUsuallyDelivPrice()   // 通常店納価格
        );

        // 通常NET価格取得
        XxcsoUsuallNetPriceVORowImpl usuallNetPriceRow
          = (XxcsoUsuallNetPriceVORowImpl)usuallNetPriceVo.first();

        //通常NET価格が取得できた場合
        if ( usuallNetPriceRow != null )
        {

          // 取得した通常店納価格を設定
          lineRow.setUsuallNetPrice(usuallNetPriceRow.getUsuallNetPrice());
        }
      }

      // 次行を取得
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    // カーソルを先頭にする
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");

  }
// 2011-04-18 v1.10 T.Yoshimoto Add End E_本稼動_01373

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

    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");
    }
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    initRow.setCopyCreateButtonRender(Boolean.FALSE);
    initRow.setInvalidityButtonRender(Boolean.FALSE);
    initRow.setApplicableButtonRender(Boolean.FALSE);
    initRow.setRevisionButtonRender(Boolean.FALSE);
    initRow.setFixedButtonRender(Boolean.FALSE);
    initRow.setQuoteSheetPrintButtonRender(Boolean.FALSE);
    initRow.setCsvCreateButtonRender(Boolean.FALSE);

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
   * Container's getter for XxcsoQuoteHeadersFullVO1
   */
  public XxcsoQuoteHeadersFullVOImpl getXxcsoQuoteHeadersFullVO1()
  {
    return (XxcsoQuoteHeadersFullVOImpl)findViewObject("XxcsoQuoteHeadersFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLinesStoreFullVO1
   */
  public XxcsoQuoteLinesStoreFullVOImpl getXxcsoQuoteLinesStoreFullVO1()
  {
    return (XxcsoQuoteLinesStoreFullVOImpl)findViewObject("XxcsoQuoteLinesStoreFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineStoreVL1
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineStoreVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineStoreVL1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017002j.server", "XxcsoQuoteStoreRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderSalesSumVO1
   */
  public XxcsoQuoteHeaderSalesSumVOImpl getXxcsoQuoteHeaderSalesSumVO1()
  {
    return (XxcsoQuoteHeaderSalesSumVOImpl)findViewObject("XxcsoQuoteHeaderSalesSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLineSalesSumVO1
   */
  public XxcsoQuoteLineSalesSumVOImpl getXxcsoQuoteLineSalesSumVO1()
  {
    return (XxcsoQuoteLineSalesSumVOImpl)findViewObject("XxcsoQuoteLineSalesSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteStoreInitVO1
   */
  public XxcsoQuoteStoreInitVOImpl getXxcsoQuoteStoreInitVO1()
  {
    return (XxcsoQuoteStoreInitVOImpl)findViewObject("XxcsoQuoteStoreInitVO1");
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
   * Container's getter for XxcsoDelivPriceTaxTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoDelivPriceTaxTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoDelivPriceTaxTypeLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUnitPriceSalesLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoUnitPriceSalesLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoUnitPriceSalesLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUnitPriceStoreLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoUnitPriceStoreLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoUnitPriceStoreLookupVO");
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
   * Container's getter for XxcsoQuoteDivLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteDivLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteDivLookupVO");
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
   * Container's getter for XxcsoQuoteLinesStoreFullVO2
   */
  public XxcsoQuoteLinesStoreFullVOImpl getXxcsoQuoteLinesStoreFullVO2()
  {
    return (XxcsoQuoteLinesStoreFullVOImpl)findViewObject("XxcsoQuoteLinesStoreFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineStoreVL2
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineStoreVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineStoreVL2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderStoreSumVO1
   */
  public XxcsoQuoteHeaderStoreSumVOImpl getXxcsoQuoteHeaderStoreSumVO1()
  {
    return (XxcsoQuoteHeaderStoreSumVOImpl)findViewObject("XxcsoQuoteHeaderStoreSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLineStoreSumVO1
   */
  public XxcsoQuoteLineStoreSumVOImpl getXxcsoQuoteLineStoreSumVO1()
  {
    return (XxcsoQuoteLineStoreSumVOImpl)findViewObject("XxcsoQuoteLineStoreSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineStoreSumVL1
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineStoreSumVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineStoreSumVL1");
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
   * Container's getter for XxcsoReferenceQuotationPriceVO1
   */
  public XxcsoReferenceQuotationPriceVOImpl getXxcsoReferenceQuotationPriceVO1()
  {
    return (XxcsoReferenceQuotationPriceVOImpl)findViewObject("XxcsoReferenceQuotationPriceVO1");
  }

// 2011-04-18 v1.10 T.Yoshimoto Add Start E_本稼動_01373
  /**
   * 
   * Container's getter for XxcsoUsuallNetPriceVO1
   */
  public XxcsoUsuallNetPriceVOImpl getXxcsoUsuallNetPriceVO1()
  {
    return (XxcsoUsuallNetPriceVOImpl)findViewObject("XxcsoUsuallNetPriceVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQtApTaxRateVO1
   */
  public XxcsoQtApTaxRateVOImpl getXxcsoQtApTaxRateVO1()
  {
    return (XxcsoQtApTaxRateVOImpl)findViewObject("XxcsoQtApTaxRateVO1");
  }
// 2011-04-18 v1.10 T.Yoshimoto Add End E_本稼動_01373
}