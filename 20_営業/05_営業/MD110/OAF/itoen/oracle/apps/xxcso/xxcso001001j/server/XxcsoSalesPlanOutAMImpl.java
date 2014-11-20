/*============================================================================
* ファイル名 : XxcsoSalesPlanOutAMImp1
* 概要説明   : 売上計画出力／アプリケーションモジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS丸山美緒　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.xxcso001001j.util.XxcsoSalesPlanConstants;

import java.io.UnsupportedEncodingException;

import java.sql.SQLException;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.BlobDomain;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;

/*******************************************************************************
 * 売上計画出力　アプリケーションモジュールクラス
 * @author  SCS丸山美緒
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanOutAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanOutAMImpl()
  {
  }
  
  /*****************************************************************************
   * カスタマイズブロック
   *****************************************************************************
   */
  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * 初期化処理
   *****************************************************************************
   */
	public void initDetails( )
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");
    initSalesPlanSearchVo();
    XxcsoUtils.debug(getOADBTransaction(), "[END]");
  }
  
  /*****************************************************************************
   * 進む（CSV作成）ボタン押下時処理
   *****************************************************************************
   */
  public void handleCsvCreateButton()
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // 検索情報リージョン
    XxcsoSalesPlanSearchVOImpl searchVo = getXxcsoSalesPlanSearchVO1();
    if ( searchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesPlanSearchVO1mpl");
    }

    // 検索情報リージョン行インスタンス
    XxcsoSalesPlanSearchVORowImpl searchRowVo =
      (XxcsoSalesPlanSearchVORowImpl) searchVo.first();
    if ( searchRowVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesPlanSearchVORowImpl");
    }

    // 拠点コード、年度の入力チェック
    this.validation(searchRowVo);

    // CSVデータ作成
    this.makeCsvData(searchRowVo);

    XxcsoUtils.debug(getOADBTransaction(), "[END]");
  }

  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * 売上計画検索情報リージョン属性設定VO初期化
   *****************************************************************************
   */
  private void initSalesPlanSearchVo()
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");
    XxcsoSalesPlanSearchVOImpl searchVo = getXxcsoSalesPlanSearchVO1();
    if ( searchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesPlanSearchVO1mpl");
    }
    searchVo.executeQuery();
    XxcsoUtils.debug(getOADBTransaction(), "[END]");
  }

  /*****************************************************************************
   * 年度、拠点コード入力チェック
   * @param  searchRowVo
   * @throw  OAException 必須項目エラー、妥当性チェック
   *****************************************************************************
   */
  private void validation(XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // 拠点コード－必須チェック
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    List errorList = new ArrayList();
    errorList
      = util.requiredCheck(
          errorList
         ,searchRowVo.getBaseCode()
         ,XxcsoSalesPlanConstants.MSG_DISP_BASECODE
         ,0
        );
        
    // 年度－必須＋妥当性チェック（４桁数字）
    errorList
      = util.checkStringToNumber(
          errorList
         ,searchRowVo.getBusinessYear()
         ,XxcsoSalesPlanConstants.MSG_DISP_BIZYEAR
         ,0
         ,4
         ,false
         ,false
         ,true
         ,0
        );

    if ( errorList.size () > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    XxcsoUtils.debug(txn, "[END]");
    return;
  }

  /*****************************************************************************
   * CSVデータ(Excelバージョン)取得
   *****************************************************************************
   */
  private StringBuffer getCsvDataExcelVer()
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // プロファイルの取得
    OADBTransaction txn  = getOADBTransaction();
    String verRoute = 
      txn.getProfile(XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_ROUTE);
    if ( verRoute == null || "".equals(verRoute.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_ROUTE
        );
    }
    String verHonbu = 
      txn.getProfile(XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_HONBU);
    if ( verHonbu == null || "".equals(verHonbu.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoSalesPlanConstants.XXCSO1_EXCEL_VER_SLSPLN_HONBU
        );
    }


    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    // CSVデータ
    return 
      new StringBuffer(
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        verRoute + 
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        XxcsoSalesPlanConstants.CSV_ITEM_DELIMITER + 
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        verHonbu + 
        XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION +
        XxcsoSalesPlanConstants.CSV_CRLF);
  }

  /*****************************************************************************
   * CSVデータ(拠点別)取得
   *****************************************************************************
   */
  private StringBuffer getCsvDataBasePlan(
    XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // 拠点別VO
    XxcsoCreateBasePlanCsvVOImpl baseVo = getXxcsoCreateBasePlanCsvVO1();
    if ( baseVo == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoCreateBasePlanCsvVOImpl");
    }

    // CallableStatement取得
    OADBTransaction         txn  = getOADBTransaction();
    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;
    stmt = 
      (OracleCallableStatement) txn.
        createCallableStatement(baseVo.getQuery(), 0);

    // 拠点別バッファ
    StringBuffer csvData = new StringBuffer();
    try
    {
      // バインドへの値の設定、ResultSet取得
      stmt.setString(1, searchRowVo.getBusinessYear()); // 年度
      stmt.setString(2, searchRowVo.getBaseCode()); 	// 拠点コード
      stmt.setString(3, searchRowVo.getBaseCode()); 	// 拠点コード
      rs = (OracleResultSet)stmt.executeQuery();

      // ResultSetループ
      while (rs.next())
      {
        // ResultSe項目取得
      	for (int i = 1; i <= XxcsoSalesPlanConstants.CSV_MAX_ITEM_ID; i++)
      	{
  	      if (i > 1) 
          {
            csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_DELIMITER);
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
          if (i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_CODE)
          {
            csvData.append(searchRowVo.getBaseCode());
          }
          else if(i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_NAME)
          {
            csvData.append(searchRowVo.getBaseName());
          }
          else
          {
            if (rs.getString(i) != null)
            {
              csvData.append((String)rs.getString(i));
            }
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
        }
        csvData.append(XxcsoSalesPlanConstants.CSV_CRLF);
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
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
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
            ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
          );
      }
    }

    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    // CSVデータ
    return csvData;
  }
  
  /*****************************************************************************
   * CSVデータ(営業員別)取得
   *****************************************************************************
   */
  private StringBuffer getCsvDataSalesPerson(
    XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    XxcsoUtils.debug(getOADBTransaction(), "[START]");

    // 営業員別VO
    XxcsoCreateSalesPersonCsvVOImpl personVo = 
      getXxcsoCreateSalesPersonCsvVO1();
    if ( personVo == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoCreateSalesPersonCsvVOImpl");
    }
    // CallableStatement取得
    OADBTransaction         txn  = getOADBTransaction();
    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;
    stmt = 
      (OracleCallableStatement) txn.
        createCallableStatement(personVo.getQuery(), 0);

    // 拠点別バッファ
    StringBuffer csvData = new StringBuffer();
    try
    {
      // バインドへの値の設定、ResultSet取得
      stmt.setString(1, searchRowVo.getBaseCode()); 	// 拠点コード
      stmt.setString(2, searchRowVo.getBaseCode()); 	// 拠点コード
      stmt.setString(3, searchRowVo.getBusinessYear()); // 年度
      stmt.setString(4, searchRowVo.getBaseCode()); 	// 拠点コード
      stmt.setString(5, searchRowVo.getBusinessYear()); // 年度
      stmt.setString(6, searchRowVo.getBaseCode()); 	// 拠点コード
      rs = (OracleResultSet)stmt.executeQuery();

      // ResultSetループ
      while (rs.next())
      {
        // ResultSe項目取得
      	for (int i = 1; i <= XxcsoSalesPlanConstants.CSV_MAX_ITEM_ID; i++)
      	{
  	      if (i > 1) 
          {
            csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_DELIMITER);
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
          if (i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_CODE)
          {
            csvData.append(searchRowVo.getBaseCode());
          }
          else if(i == XxcsoSalesPlanConstants.CSV_ITEM_ID_BASE_NAME)
          {
            csvData.append(searchRowVo.getBaseName());
          }
          else
          {
            if (rs.getString(i) != null)
            {
              csvData.append((String)rs.getString(i));
            }
          }
          csvData.append(XxcsoSalesPlanConstants.CSV_ITEM_QUOTATION);
        }
        csvData.append(XxcsoSalesPlanConstants.CSV_CRLF);
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
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
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
            ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
          );
      }
    }

    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    // CSVデータ
    return csvData;

  }
  
  /*****************************************************************************
   * CSVデータ出力
   *****************************************************************************
   */
  private void makeCsvData(XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    // CSVデータ生成処理 Start
    OADBTransaction txn  = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // プロファイルの取得
    String clientEnc = txn.getProfile(XxcsoConstants.XXCSO1_CLIENT_ENCODE);
    if ( clientEnc == null || "".equals(clientEnc.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.XXCSO1_CLIENT_ENCODE
        );
    }

    // ファイルダウンロードVOインスタンス
    XxcsoCsvDownVOImpl csvVo = getXxcsoCsvDownVO1();
    if ( csvVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVOImpl");
    }

    // ファイルダウンロード行VOインスタンス
    XxcsoCsvDownVORowImpl csvRowVo
      = (XxcsoCsvDownVORowImpl)csvVo.createRow();
    if ( csvRowVo == null )
    {
        throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVORowImpl");
    }

    // ファイル名取得
    String sbFileName = getFileName(searchRowVo);
    
    // CSVデータ取得
    StringBuffer sbFileData = getCsvDataExcelVer();
    int verLen = sbFileData.length();
    sbFileData.append(getCsvDataBasePlan(searchRowVo));
    sbFileData.append(getCsvDataSalesPerson(searchRowVo));

    // 対象データなし
    if ( verLen == sbFileData.length() )
    {
      // エラー：対象データなし
      throw
        XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00454
        );
    }

    try
    {
      // ファイル名、ファイルデータ等を設定
      csvRowVo.setBusinessYear(searchRowVo.getBusinessYear());
      csvRowVo.setBaseName(searchRowVo.getBaseName());
      csvRowVo.setFileName(sbFileName);
      csvRowVo.setFileData(
        new BlobDomain(sbFileData.toString().getBytes(clientEnc))
      );
    }
    catch (UnsupportedEncodingException uae)
    {
      throw
          XxcsoMessage.createCsvErrorMessage(uae);
    }

    // VOに出力
    csvVo.last();
    csvVo.next();
    csvVo.insertRow(csvRowVo);

    // 成功メッセージを設定する
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoSalesPlanConstants.MSG_DISP_CSV);
    sbMsg.append(sbFileName);

    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoSalesPlanConstants.MSG_DISP_OUT
        );
        
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ファイル名取得
   *****************************************************************************
   */
  private String getFileName(XxcsoSalesPlanSearchVORowImpl searchRowVo)
  {
    OADBTransaction txn  = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // CSVファイル名の生成(拠点コード_年度_download_yyyymmddhh24miss.csv)
    StringBuffer sbFileName = new StringBuffer(120);
    sbFileName.append(searchRowVo.getBaseCode());
    sbFileName.append(XxcsoSalesPlanConstants.CSV_NAME_DELIMITER);
    sbFileName.append(searchRowVo.getBusinessYear());
    sbFileName.append(XxcsoSalesPlanConstants.CSV_NAME_KEY);
    sbFileName.append(XxcsoAcctSalesPlansUtils.getSysdateTimeString(txn));
    sbFileName.append(XxcsoSalesPlanConstants.CSV_EXTENSION);

    XxcsoUtils.debug(getOADBTransaction(), "[END]");

    return sbFileName.toString();
  }
  
  /*****************************************************************************
   * OAF Auto Generate
   *****************************************************************************
   */
  /**
   * 
   * Container's getter for XxcsoCreateBasePlanCsvVO1
   */
  public XxcsoCreateBasePlanCsvVOImpl getXxcsoCreateBasePlanCsvVO1()
  {
    return (XxcsoCreateBasePlanCsvVOImpl)findViewObject("XxcsoCreateBasePlanCsvVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCreateSalesPersonCsvVO1
   */
  public XxcsoCreateSalesPersonCsvVOImpl getXxcsoCreateSalesPersonCsvVO1()
  {
    return (XxcsoCreateSalesPersonCsvVOImpl)findViewObject("XxcsoCreateSalesPersonCsvVO1");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso001001j.server", "XxcsoSalesPlanOutAMLocal");
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
   * Container's getter for XxcsoSalesPlanSearchVO1
   */
  public XxcsoSalesPlanSearchVOImpl getXxcsoSalesPlanSearchVO1()
  {
    return (XxcsoSalesPlanSearchVOImpl)findViewObject("XxcsoSalesPlanSearchVO1");
  }


}