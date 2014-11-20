/*============================================================================
* ファイル名 : XxcsoQuoteSearchAMImpl
* 概要説明   : 見積検索アプリケーション・モジュールクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS張吉      新規作成
* 2012-09-10 1.1  SCSK穆宏旭  【E_本稼動_09945】見積書の照会方法の変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.server;

import itoen.oracle.apps.xxcso.xxcso017006j.util.XxcsoQuoteSearchConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * 見積を検索するためのアプリケーション・モジュールクラスです。
 * @author  SCS張吉
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteSearchAMImpl extends OAApplicationModuleImpl 
{
 
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearchAMImpl()
  {
  }
  
  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @throw OAException
   *****************************************************************************
   */
  public void initDetails()
  {
    //条件初期化
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteSearchTermsVOImpl");
    }
    // 他画面からの遷移考慮
    if ( !termsVo.isPreparedForExecution() )
    {
      // 初期化処理実行
      termsVo.executeQuery();
    }

    XxcsoLookupListVOImpl quoteTypeListVo = getXxcsoQuoteTypeListVO();
    if ( quoteTypeListVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteTypeListVO");
    }
    
    // 見積種別取得
    quoteTypeListVo.initQuery(
      "XXCSO1_QUOTE_TYPE"
     ,"lookup_code"
    );
  }

  /*****************************************************************************
   * 進むボタンを押下した際の処理です。
   * @return HashMap
   * @throw  OAException
   *****************************************************************************
   */
  // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod Start
  //public HashMap executeSearch()
    public HashMap executeSearch(String searchStandard)
  // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod End
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[executeSearch]");

    HashMap retMap = new HashMap();

    // 検索条件取得
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVOImpl");
    }

    XxcsoQuoteSearchTermsVORowImpl paramRow
      = (XxcsoQuoteSearchTermsVORowImpl)termsVo.first();
    if ( paramRow == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVORowImpl");
    }

    XxcsoUtils.debug(txn, "QuoteType : " + paramRow.getQuoteType());
    XxcsoUtils.debug(txn, "QuoteNumber : " + paramRow.getQuoteNumber());
    XxcsoUtils.debug(txn, "QuoteRevisionNumber : " + paramRow.getQuoteRevisionNumber());

    // 入力パラメータチェック
    List errorList = this.paramCheck(paramRow);
    // エラーがある場合
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // 版が入力されている場合
    if ( (paramRow.getQuoteRevisionNumber() != null) 
           && (!"".equals(paramRow.getQuoteRevisionNumber())) )
    {
      XxcsoQuoteSearch1VOImpl searchVo1 = getXxcsoQuoteSearch1VO1();
      if ( searchVo1 == null )
      {
        throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSearch1VOImpl");
      }
      
      XxcsoUtils.debug(txn, "[版が入力されている]");
      
      // 検索実行
      searchVo1.initQuery(
        paramRow.getQuoteType(),
        paramRow.getQuoteNumber(),
        String.valueOf(Integer.parseInt(paramRow.getQuoteRevisionNumber()))
      );

      // 件数チェック(firstでnullチェック)
      XxcsoQuoteSearch1VORowImpl searchRow1
        = (XxcsoQuoteSearch1VORowImpl)searchVo1.first();

      // 検索結果がない場合
      if (searchRow1 == null) 
      {
        throw XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00466
             ,XxcsoConstants.TOKEN_QUOTE_NUMBER
             ,paramRow.getQuoteNumber()
             ,XxcsoConstants.TOKEN_QUOTE_R_N
             ,paramRow.getQuoteRevisionNumber()
            );
      }

      // 見積ヘッダーID
      retMap.put(
        XxcsoConstants.TRANSACTION_KEY1,
        searchRow1.getQuoteHeaderId()
      );
      // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod Start
      // 実行区分
      //retMap.put(
      //    XxcsoConstants.EXECUTE_MODE,
      //    XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
      //);
      //上記取得したプロファイル値が3の場合、実行区分にREAD_ONLYを設定
      //上記取得したプロファイル値が3以外の場合、実行区分にUPDATEを設定
      // 実行区分
      if ( null != searchStandard && 
           !"".equals(searchStandard) && 
           searchStandard.equals(
           XxcsoQuoteSearchConstants.XXCSO1_QUOTE_STANDARD_VALUE_3))
      {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_READ_ONLY
        );
      } else {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
        );
      }
      // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod End
    }
    else
    {
      XxcsoQuoteSearch2VOImpl searchVo2 = getXxcsoQuoteSearch2VO1();
      if ( searchVo2 == null )
      {
        throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSearch2VOImpl");
      }
      
       XxcsoUtils.debug(txn, "[版が未入力]");
       
      // 検索実行
     searchVo2.initQuery(
        paramRow.getQuoteType(),
        paramRow.getQuoteNumber()
      );
      
      // 件数チェック(firstでnullチェック)
      XxcsoQuoteSearch2VORowImpl searchRow2
        = (XxcsoQuoteSearch2VORowImpl)searchVo2.first();

      // 検索結果がない場合
      if (searchRow2 == null) 
      {
        throw XxcsoMessage.createErrorMessage(
              "APP-XXCSO1-00466"
             ,"QUOTE_NUMBER"
             ,paramRow.getQuoteNumber()
             ,"QUOTE_REVISION_NUMBER"
             ,paramRow.getQuoteRevisionNumber()
            );
      }
      
      // 見積ヘッダーID
      retMap.put(
        XxcsoConstants.TRANSACTION_KEY1,
        searchRow2.getQuoteHeaderId()
      );
      // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod Start
      // 実行区分
      //retMap.put(
      //  XxcsoConstants.EXECUTE_MODE,
      //  XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
      //);
      //上記取得したプロファイル値が3の場合、実行区分にREAD_ONLYを設定
      //上記取得したプロファイル値が3以外の場合、実行区分にUPDATEを設定
      if ( null != searchStandard && 
           !"".equals(searchStandard) &&
           searchStandard.equals(
           XxcsoQuoteSearchConstants.XXCSO1_QUOTE_STANDARD_VALUE_3))
      {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_READ_ONLY
        );
      } else {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
        );      
      }
      // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod End
    }

    return retMap;
  }

  /*****************************************************************************
   * 消去ボタンを押下した際の処理です。
   * @throw OAException
   *****************************************************************************
   */
  public void ClearBtn()
  {
    // 検索条件初期化
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteSearchTermsVOImpl");
    }
    termsVo.executeQuery();
  }

  /*****************************************************************************
   * 見積種別を返す。
   * @return quoteType;
   * @throw OAException
   *****************************************************************************
   */
  public String getQuoteType()
  {
    // 見積種別取得
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVOImpl");
    }

    XxcsoQuoteSearchTermsVORowImpl paramRow
      = (XxcsoQuoteSearchTermsVORowImpl)termsVo.first();
    if ( paramRow == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVORowImpl");
    }

    return paramRow.getQuoteType();
  }

  /*****************************************************************************
   * 検索パラメータエラーチェック処理です。
   * @return List errorList
   * @throw  OAException
   *****************************************************************************
   */
  private List paramCheck(XxcsoQuoteSearchTermsVORowImpl paramRow)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[paramCheck]");

    // 入力チェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    
    List errorList = new ArrayList();

    // 見積種別の必須チェック
    errorList
      = util.requiredCheck(
          errorList
         ,paramRow.getQuoteType()
         ,XxcsoQuoteSearchConstants.TOKEN_VALUE_QUOTE_TYPE
         ,0
        );
        
    // 見積番号の必須チェック
    errorList
      = util.requiredCheck(
          errorList
         ,paramRow.getQuoteNumber()
         ,XxcsoQuoteSearchConstants.TOKEN_VALUE_QUOTE_NUMBER
         ,0
        );
        
    // 版の数値チェック
    errorList
      = util.checkStringToNumber(
          errorList
         ,paramRow.getQuoteRevisionNumber()
         ,XxcsoQuoteSearchConstants.TOKEN_VALUE_QUOTE_REVISION_NUMBER
         ,0
         ,2
         ,true
         ,true
         ,false
         ,0
        );    

    return errorList;    
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017006j.server", "XxcsoQuoteSearchAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearch1VO1
   */
  public XxcsoQuoteSearch1VOImpl getXxcsoQuoteSearch1VO1()
  {
    return (XxcsoQuoteSearch1VOImpl)findViewObject("XxcsoQuoteSearch1VO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearch2VO1
   */
  public XxcsoQuoteSearch2VOImpl getXxcsoQuoteSearch2VO1()
  {
    return (XxcsoQuoteSearch2VOImpl)findViewObject("XxcsoQuoteSearch2VO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearchTermsVO1
   */
  public XxcsoQuoteSearchTermsVOImpl getXxcsoQuoteSearchTermsVO1()
  {
    return (XxcsoQuoteSearchTermsVOImpl)findViewObject("XxcsoQuoteSearchTermsVO1");
  }
}