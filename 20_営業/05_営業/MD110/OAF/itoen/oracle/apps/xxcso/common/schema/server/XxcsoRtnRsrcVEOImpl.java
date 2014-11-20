/*============================================================================
* ファイル名 : XxcsoRtnRsrcVEOImpl
* 概要説明   : ルートNo/担当営業員エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-05 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.AttributeList;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.sql.SQLException;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * ルートNo/担当営業員のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcVEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int ACCOUNTNUMBER = 0;
  protected static final int CUSTACCOUNTID = 1;
  protected static final int CREATEDBY = 2;
  protected static final int CREATIONDATE = 3;
  protected static final int LASTUPDATEDBY = 4;
  protected static final int LASTUPDATEDATE = 5;
  protected static final int LASTUPDATELOGIN = 6;
  protected static final int TRGTROUTENO = 7;
  protected static final int TRGTROUTENOSTARTDATE = 8;
  protected static final int TRGTROUTENOEXTENSIONID = 9;
  protected static final int TRGTROUTENOLASTUPDDATE = 10;
  protected static final int NEXTROUTENO = 11;
  protected static final int NEXTROUTENOSTARTDATE = 12;
  protected static final int NEXTROUTENOEXTENSIONID = 13;
  protected static final int NEXTROUTENOLASTUPDDATE = 14;
  protected static final int NEWROUTENO = 15;
  protected static final int NEWROUTENOSTARTDATE = 16;
  protected static final int NEWROUTENOEXTENSIONID = 17;
  protected static final int TRGTRESOURCE = 18;
  protected static final int TRGTRESOURCESTARTDATE = 19;
  protected static final int TRGTRESOURCEEXTENSIONID = 20;
  protected static final int TRGTRESOURCELASTUPDDATE = 21;
  protected static final int NEXTRESOURCE = 22;
  protected static final int NEXTRESOURCESTARTDATE = 23;
  protected static final int NEXTRESOURCEEXTENSIONID = 24;
  protected static final int NEXTRESOURCELASTUPDDATE = 25;
  protected static final int NEWRESOURCE = 26;
  protected static final int NEWRESOURCESTARTDATE = 27;
  protected static final int NEWRESOURCEEXTENSIONID = 28;
  protected static final int OLDCUSTACCOUNTID = 29;
  protected static final int TRGTRESOURCECNT = 30;
  protected static final int NEXTRESOURCECNT = 31;


















  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcVEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoRtnRsrcVEO");
    }
    return mDefinitionObject;
  }




















  /*****************************************************************************
   * エンティティエキスパートインスタンスの取得処理です。
   * @param txn OADBTransactionインスタンス
   *****************************************************************************
   */
  public static XxcsoCommonEntityExpert getXxcsoCommonEntityExpert(
    OADBTransaction txn
  )
  {
    return
      (XxcsoCommonEntityExpert)
        txn.getExpert(XxcsoQuoteHeadersEOImpl.getDefinitionObject());
  }


  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl def = XxcsoRtnRsrcVEOImpl.getDefinitionObject();
    Iterator it = def.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while ( it.hasNext() )
    {
      XxcsoRtnRsrcVEOImpl eo = (XxcsoRtnRsrcVEOImpl)it.next();
      if ( eo.getEntityState() == STATUS_NEW )
      {
        int value = eo.getCustAccountId().intValue();
        if ( minValue > value )
        {
          minValue = value;
        }
      }
    }

    minValue--;

    setCustAccountId(new Number(minValue));
    setOldCustAccountId(getCustAccountId());
    
    super.create(list);

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコードロック処理です。
   * ルート管理はレコードロックを行わないため、空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.setLocked(true);
    
    XxcsoUtils.debug(txn, "[END]");

  }


  /*****************************************************************************
   * レコード作成処理です。
   * ルートNo/担当営業員登録APIをCallします。
   * レコード更新処理と同様の処理を行います。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    processApiCall();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * レコード更新処理です。
   * ルートNo/担当営業員登録APIをCallします。
   * レコード作成処理と同様の処理を行います。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    processApiCall();

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード削除処理です。
   * 呼ばれないはずなので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * ルートNo/担当営業員登録APIをCallします。
   *****************************************************************************
   */
  private void processApiCall()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");


    // ルートNo（当月）の更新確認
    if ( super.isAttributeChanged(TRGTROUTENO) )
    {
      String routeNo = getTrgtRouteNo();
      Date startDate = getTrgtRouteNoStartDate();
      Number extensionId = getTrgtRouteNoExtensionId();
      if ( routeNo == null || "".equals(routeNo) )
      {
        unRegistRouteNo(routeNo, startDate, extensionId);
      }
      else
      {
        registRouteNo(routeNo, startDate, extensionId);
      }
    }
    
    // ルートNo（翌月以降）の更新確認
    if ( super.isAttributeChanged(NEXTROUTENO) )
    {
      String routeNo = getNextRouteNo();
      Date startDate = getNextRouteNoStartDate();
      Number extensionId = getNextRouteNoExtensionId();
      if ( routeNo == null || "".equals(routeNo) )
      {
        unRegistRouteNo(routeNo, startDate, extensionId);
      }
      else
      {
        registRouteNo(routeNo, startDate, extensionId);
      }
    }

    // 新ルートNoの更新確認
    if ( super.isAttributeChanged(NEWROUTENO) )
    {
      String routeNo = getNewRouteNo();
      Date startDate = getNewRouteNoStartDate();
      Number extensionId = getNewRouteNoExtensionId();
      if ( routeNo == null || "".equals(routeNo) )
      {
        unRegistRouteNo(routeNo, startDate, extensionId);
      }
      else
      {
        registRouteNo(routeNo, startDate, extensionId);
      }
    }

    // 担当営業員（当月）の更新確認
    if ( super.isAttributeChanged(TRGTRESOURCE) )
    {
      String resourceNo = getTrgtResource();
      Date startDate = getTrgtResourceStartDate();
      Number extensionId = getTrgtResourceExtensionId();
      if ( resourceNo == null || "".equals(resourceNo) )
      {
        unRegistResourceNo(resourceNo, startDate, extensionId);
      }
      else
      {
        registResourceNo(resourceNo, startDate, extensionId);
      }
    }

    // 担当営業員（翌月）の更新確認
    if ( super.isAttributeChanged(NEXTRESOURCE) )
    {
      String resourceNo = getNextResource();
      Date startDate = getNextResourceStartDate();
      Number extensionId = getNextResourceExtensionId();
      if ( resourceNo == null || "".equals(resourceNo) )
      {
        unRegistResourceNo(resourceNo, startDate, extensionId);
      }
      else
      {
        registResourceNo(resourceNo, startDate, extensionId);
      }
    }
    
    // 新担当営業員の更新確認
    if ( super.isAttributeChanged(NEWRESOURCE) )
    {
      String resourceNo = getNewResource();
      Date startDate = getNewResourceStartDate();
      Number extensionId = getNewResourceExtensionId();
      if ( resourceNo == null || "".equals(resourceNo) )
      {
        unRegistResourceNo(resourceNo, startDate, extensionId);
      }
      else
      {
        registResourceNo(resourceNo, startDate, extensionId);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  
  /*****************************************************************************
   * ルートNo登録APIをCallします。
   *****************************************************************************
   */
  private void registRouteNo(
    String  routeNo
   ,Date    startDate
   ,Number  extensionId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String accountNumber = getAccountNumber();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rtn_rsrc_pkg.regist_route_no(");
    sql.append("    iv_account_number    => :1");
    sql.append("   ,iv_route_no          => :2");
    sql.append("   ,id_start_date        => :3");
    sql.append("   ,ov_errbuf            => :4");
    sql.append("   ,ov_retcode           => :5");
    sql.append("   ,ov_errmsg            => :6");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, accountNumber);
      stmt.setString(2, routeNo);
      stmt.setDATE(3, startDate);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(4);
      String retCode = stmt.getString(5);
      String errMsg  = stmt.getString(6);

      XxcsoUtils.debug(txn, "errbuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retcode = " + retCode);
      XxcsoUtils.debug(txn, "errmsg  = " + errMsg);
      
      if ( ! "0".equals(retCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_ROUTE_NO
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_REGIST
           ,errBuf
          );
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_ROUTE_NO
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_REGIST
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
   * ルートNo削除APIをCallします。
   *****************************************************************************
   */
  private void unRegistRouteNo(
    String  routeNo
   ,Date    startDate
   ,Number  extensionId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( extensionId == null )
    {
      XxcsoUtils.debug(txn, "extensionId is null");
      return;
    }
    
    String accountNumber = getAccountNumber();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rtn_rsrc_pkg.unregist_route_no(");
    sql.append("    iv_account_number    => :1");
    sql.append("   ,iv_route_no          => :2");
    sql.append("   ,id_start_date        => :3");
    sql.append("   ,ov_errbuf            => :4");
    sql.append("   ,ov_retcode           => :5");
    sql.append("   ,ov_errmsg            => :6");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, accountNumber);
      stmt.setString(2, routeNo);
      stmt.setDATE(3, startDate);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(4);
      String retCode = stmt.getString(5);
      String errMsg  = stmt.getString(6);

      XxcsoUtils.debug(txn, "errbuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retcode = " + retCode);
      XxcsoUtils.debug(txn, "errmsg  = " + errMsg);
      
      if ( ! "0".equals(retCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_ROUTE_NO
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_DELETE
           ,errBuf
          );
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_ROUTE_NO
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_DELETE
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
   * 担当営業員登録APIをCallします。
   *****************************************************************************
   */
  private void registResourceNo(
    String  resourceNo
   ,Date    startDate
   ,Number  extensionId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String accountNumber = getAccountNumber();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rtn_rsrc_pkg.regist_resource_no(");
    sql.append("    iv_account_number    => :1");
    sql.append("   ,iv_resource_no       => :2");
    sql.append("   ,id_start_date        => :3");
    sql.append("   ,ov_errbuf            => :4");
    sql.append("   ,ov_retcode           => :5");
    sql.append("   ,ov_errmsg            => :6");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, accountNumber);
      stmt.setString(2, resourceNo);
      stmt.setDATE(3, startDate);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(4);
      String retCode = stmt.getString(5);
      String errMsg  = stmt.getString(6);

      XxcsoUtils.debug(txn, "errbuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retcode = " + retCode);
      XxcsoUtils.debug(txn, "errmsg  = " + errMsg);
      
      if ( ! "0".equals(retCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_RESOURCE_NO
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_REGIST
           ,errBuf
          );
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_RESOURCE_NO
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_REGIST
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
   * 担当営業員削除APIをCallします。
   *****************************************************************************
   */
  private void unRegistResourceNo(
    String  resourceNo
   ,Date    startDate
   ,Number  extensionId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( extensionId == null )
    {
      XxcsoUtils.debug(txn, "extensionId is null");
      return;
    }
    
    String accountNumber = getAccountNumber();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rtn_rsrc_pkg.unregist_resource_no(");
    sql.append("    iv_account_number    => :1");
    sql.append("   ,iv_resource_no       => :2");
    sql.append("   ,id_start_date        => :3");
    sql.append("   ,ov_errbuf            => :4");
    sql.append("   ,ov_retcode           => :5");
    sql.append("   ,ov_errmsg            => :6");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, accountNumber);
      stmt.setString(2, resourceNo);
      stmt.setDATE(3, startDate);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(4);
      String retCode = stmt.getString(5);
      String errMsg  = stmt.getString(6);

      XxcsoUtils.debug(txn, "errbuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retcode = " + retCode);
      XxcsoUtils.debug(txn, "errmsg  = " + errMsg);
      
      if ( ! "0".equals(retCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_RESOURCE_NO
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_DELETE
           ,errBuf
          );
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_RESOURCE_NO
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_DELETE
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

  


  /**
   * 
   * Gets the attribute value for AccountNumber, using the alias name AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for setAccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtRouteNo, using the alias name TrgtRouteNo
   */
  public String getTrgtRouteNo()
  {
    return (String)getAttributeInternal(TRGTROUTENO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtRouteNo
   */
  public void setTrgtRouteNo(String value)
  {
    setAttributeInternal(TRGTROUTENO, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtRouteNoStartDate, using the alias name TrgtRouteNoStartDate
   */
  public Date getTrgtRouteNoStartDate()
  {
    return (Date)getAttributeInternal(TRGTROUTENOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtRouteNoStartDate
   */
  public void setTrgtRouteNoStartDate(Date value)
  {
    setAttributeInternal(TRGTROUTENOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtRouteNoExtensionId, using the alias name TrgtRouteNoExtensionId
   */
  public Number getTrgtRouteNoExtensionId()
  {
    return (Number)getAttributeInternal(TRGTROUTENOEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtRouteNoExtensionId
   */
  public void setTrgtRouteNoExtensionId(Number value)
  {
    setAttributeInternal(TRGTROUTENOEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtRouteNoLastUpdDate, using the alias name TrgtRouteNoLastUpdDate
   */
  public Date getTrgtRouteNoLastUpdDate()
  {
    return (Date)getAttributeInternal(TRGTROUTENOLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtRouteNoLastUpdDate
   */
  public void setTrgtRouteNoLastUpdDate(Date value)
  {
    setAttributeInternal(TRGTROUTENOLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NextRouteNo, using the alias name NextRouteNo
   */
  public String getNextRouteNo()
  {
    return (String)getAttributeInternal(NEXTROUTENO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextRouteNo
   */
  public void setNextRouteNo(String value)
  {
    setAttributeInternal(NEXTROUTENO, value);
  }

  /**
   * 
   * Gets the attribute value for NextRouteNoStartDate, using the alias name NextRouteNoStartDate
   */
  public Date getNextRouteNoStartDate()
  {
    return (Date)getAttributeInternal(NEXTROUTENOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextRouteNoStartDate
   */
  public void setNextRouteNoStartDate(Date value)
  {
    setAttributeInternal(NEXTROUTENOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NextRouteNoExtensionId, using the alias name NextRouteNoExtensionId
   */
  public Number getNextRouteNoExtensionId()
  {
    return (Number)getAttributeInternal(NEXTROUTENOEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextRouteNoExtensionId
   */
  public void setNextRouteNoExtensionId(Number value)
  {
    setAttributeInternal(NEXTROUTENOEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for NextRouteNoLastUpdDate, using the alias name NextRouteNoLastUpdDate
   */
  public Date getNextRouteNoLastUpdDate()
  {
    return (Date)getAttributeInternal(NEXTROUTENOLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextRouteNoLastUpdDate
   */
  public void setNextRouteNoLastUpdDate(Date value)
  {
    setAttributeInternal(NEXTROUTENOLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NewRouteNo, using the alias name NewRouteNo
   */
  public String getNewRouteNo()
  {
    return (String)getAttributeInternal(NEWROUTENO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewRouteNo
   */
  public void setNewRouteNo(String value)
  {
    setAttributeInternal(NEWROUTENO, value);
  }

  /**
   * 
   * Gets the attribute value for NewRouteNoStartDate, using the alias name NewRouteNoStartDate
   */
  public Date getNewRouteNoStartDate()
  {
    return (Date)getAttributeInternal(NEWROUTENOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewRouteNoStartDate
   */
  public void setNewRouteNoStartDate(Date value)
  {
    setAttributeInternal(NEWROUTENOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtResource, using the alias name TrgtResource
   */
  public String getTrgtResource()
  {
    return (String)getAttributeInternal(TRGTRESOURCE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtResource
   */
  public void setTrgtResource(String value)
  {
    setAttributeInternal(TRGTRESOURCE, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtResourceStartDate, using the alias name TrgtResourceStartDate
   */
  public Date getTrgtResourceStartDate()
  {
    return (Date)getAttributeInternal(TRGTRESOURCESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtResourceStartDate
   */
  public void setTrgtResourceStartDate(Date value)
  {
    setAttributeInternal(TRGTRESOURCESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtResourceExtensionId, using the alias name TrgtResourceExtensionId
   */
  public Number getTrgtResourceExtensionId()
  {
    return (Number)getAttributeInternal(TRGTRESOURCEEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtResourceExtensionId
   */
  public void setTrgtResourceExtensionId(Number value)
  {
    setAttributeInternal(TRGTRESOURCEEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for TrgtResourceLastUpdDate, using the alias name TrgtResourceLastUpdDate
   */
  public Date getTrgtResourceLastUpdDate()
  {
    return (Date)getAttributeInternal(TRGTRESOURCELASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtResourceLastUpdDate
   */
  public void setTrgtResourceLastUpdDate(Date value)
  {
    setAttributeInternal(TRGTRESOURCELASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NextResource, using the alias name NextResource
   */
  public String getNextResource()
  {
    return (String)getAttributeInternal(NEXTRESOURCE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextResource
   */
  public void setNextResource(String value)
  {
    setAttributeInternal(NEXTRESOURCE, value);
  }

  /**
   * 
   * Gets the attribute value for NextResourceStartDate, using the alias name NextResourceStartDate
   */
  public Date getNextResourceStartDate()
  {
    return (Date)getAttributeInternal(NEXTRESOURCESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextResourceStartDate
   */
  public void setNextResourceStartDate(Date value)
  {
    setAttributeInternal(NEXTRESOURCESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NextResourceExtensionId, using the alias name NextResourceExtensionId
   */
  public Number getNextResourceExtensionId()
  {
    return (Number)getAttributeInternal(NEXTRESOURCEEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextResourceExtensionId
   */
  public void setNextResourceExtensionId(Number value)
  {
    setAttributeInternal(NEXTRESOURCEEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for NextResourceLastUpdDate, using the alias name NextResourceLastUpdDate
   */
  public Date getNextResourceLastUpdDate()
  {
    return (Date)getAttributeInternal(NEXTRESOURCELASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextResourceLastUpdDate
   */
  public void setNextResourceLastUpdDate(Date value)
  {
    setAttributeInternal(NEXTRESOURCELASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NewResource, using the alias name NewResource
   */
  public String getNewResource()
  {
    return (String)getAttributeInternal(NEWRESOURCE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewResource
   */
  public void setNewResource(String value)
  {
    setAttributeInternal(NEWRESOURCE, value);
  }

  /**
   * 
   * Gets the attribute value for NewResourceStartDate, using the alias name NewResourceStartDate
   */
  public Date getNewResourceStartDate()
  {
    return (Date)getAttributeInternal(NEWRESOURCESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewResourceStartDate
   */
  public void setNewResourceStartDate(Date value)
  {
    setAttributeInternal(NEWRESOURCESTARTDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case CUSTACCOUNTID:
        return getCustAccountId();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case TRGTROUTENO:
        return getTrgtRouteNo();
      case TRGTROUTENOSTARTDATE:
        return getTrgtRouteNoStartDate();
      case TRGTROUTENOEXTENSIONID:
        return getTrgtRouteNoExtensionId();
      case TRGTROUTENOLASTUPDDATE:
        return getTrgtRouteNoLastUpdDate();
      case NEXTROUTENO:
        return getNextRouteNo();
      case NEXTROUTENOSTARTDATE:
        return getNextRouteNoStartDate();
      case NEXTROUTENOEXTENSIONID:
        return getNextRouteNoExtensionId();
      case NEXTROUTENOLASTUPDDATE:
        return getNextRouteNoLastUpdDate();
      case NEWROUTENO:
        return getNewRouteNo();
      case NEWROUTENOSTARTDATE:
        return getNewRouteNoStartDate();
      case NEWROUTENOEXTENSIONID:
        return getNewRouteNoExtensionId();
      case TRGTRESOURCE:
        return getTrgtResource();
      case TRGTRESOURCESTARTDATE:
        return getTrgtResourceStartDate();
      case TRGTRESOURCEEXTENSIONID:
        return getTrgtResourceExtensionId();
      case TRGTRESOURCELASTUPDDATE:
        return getTrgtResourceLastUpdDate();
      case NEXTRESOURCE:
        return getNextResource();
      case NEXTRESOURCESTARTDATE:
        return getNextResourceStartDate();
      case NEXTRESOURCEEXTENSIONID:
        return getNextResourceExtensionId();
      case NEXTRESOURCELASTUPDDATE:
        return getNextResourceLastUpdDate();
      case NEWRESOURCE:
        return getNewResource();
      case NEWRESOURCESTARTDATE:
        return getNewResourceStartDate();
      case NEWRESOURCEEXTENSIONID:
        return getNewResourceExtensionId();
      case OLDCUSTACCOUNTID:
        return getOldCustAccountId();
      case TRGTRESOURCECNT:
        return getTrgtResourceCnt();
      case NEXTRESOURCECNT:
        return getNextResourceCnt();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case TRGTROUTENO:
        setTrgtRouteNo((String)value);
        return;
      case TRGTROUTENOSTARTDATE:
        setTrgtRouteNoStartDate((Date)value);
        return;
      case TRGTROUTENOEXTENSIONID:
        setTrgtRouteNoExtensionId((Number)value);
        return;
      case TRGTROUTENOLASTUPDDATE:
        setTrgtRouteNoLastUpdDate((Date)value);
        return;
      case NEXTROUTENO:
        setNextRouteNo((String)value);
        return;
      case NEXTROUTENOSTARTDATE:
        setNextRouteNoStartDate((Date)value);
        return;
      case NEXTROUTENOEXTENSIONID:
        setNextRouteNoExtensionId((Number)value);
        return;
      case NEXTROUTENOLASTUPDDATE:
        setNextRouteNoLastUpdDate((Date)value);
        return;
      case NEWROUTENO:
        setNewRouteNo((String)value);
        return;
      case NEWROUTENOSTARTDATE:
        setNewRouteNoStartDate((Date)value);
        return;
      case NEWROUTENOEXTENSIONID:
        setNewRouteNoExtensionId((Number)value);
        return;
      case TRGTRESOURCE:
        setTrgtResource((String)value);
        return;
      case TRGTRESOURCESTARTDATE:
        setTrgtResourceStartDate((Date)value);
        return;
      case TRGTRESOURCEEXTENSIONID:
        setTrgtResourceExtensionId((Number)value);
        return;
      case TRGTRESOURCELASTUPDDATE:
        setTrgtResourceLastUpdDate((Date)value);
        return;
      case NEXTRESOURCE:
        setNextResource((String)value);
        return;
      case NEXTRESOURCESTARTDATE:
        setNextResourceStartDate((Date)value);
        return;
      case NEXTRESOURCEEXTENSIONID:
        setNextResourceExtensionId((Number)value);
        return;
      case NEXTRESOURCELASTUPDDATE:
        setNextResourceLastUpdDate((Date)value);
        return;
      case NEWRESOURCE:
        setNewResource((String)value);
        return;
      case NEWRESOURCESTARTDATE:
        setNewResourceStartDate((Date)value);
        return;
      case NEWRESOURCEEXTENSIONID:
        setNewResourceExtensionId((Number)value);
        return;
      case OLDCUSTACCOUNTID:
        setOldCustAccountId((Number)value);
        return;
      case TRGTRESOURCECNT:
        setTrgtResourceCnt((Number)value);
        return;
      case NEXTRESOURCECNT:
        setNextResourceCnt((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the attribute value for NewRouteNoExtensionId, using the alias name NewRouteNoExtensionId
   */
  public Number getNewRouteNoExtensionId()
  {
    return (Number)getAttributeInternal(NEWROUTENOEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewRouteNoExtensionId
   */
  public void setNewRouteNoExtensionId(Number value)
  {
    setAttributeInternal(NEWROUTENOEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for NewResourceExtensionId, using the alias name NewResourceExtensionId
   */
  public Number getNewResourceExtensionId()
  {
    return (Number)getAttributeInternal(NEWRESOURCEEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewResourceExtensionId
   */
  public void setNewResourceExtensionId(Number value)
  {
    setAttributeInternal(NEWRESOURCEEXTENSIONID, value);
  }


  /**
   * 
   * Gets the attribute value for CustAccountId, using the alias name CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /*****************************************************************************
   * 顧客IDの設定処理です。
   * 重複した顧客IDが設定されないようエラーハンドリングします。
   *****************************************************************************
   */
  public void setCustAccountId(Number value)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl def = XxcsoRtnRsrcVEOImpl.getDefinitionObject();
    Iterator it = def.getAllEntityInstancesIterator(txn);

    while ( it.hasNext() )
    {
      XxcsoRtnRsrcVEOImpl eo = (XxcsoRtnRsrcVEOImpl)it.next();
      if ( eo.getCustAccountId() == null || "".equals(eo.getCustAccountId()) )
      {
        continue;
      }

      if ( eo.getCustAccountId().equals(value) )
      {
        XxcsoCommonEntityExpert expert
          = XxcsoRtnRsrcVEOImpl.getXxcsoCommonEntityExpert(txn);

        String partyName = expert.getPartyName(eo.getAccountNumber());
        
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00474
           ,XxcsoConstants.TOKEN_ACCOUNT
           ,partyName
          );
      }
    }

    Number setValue = value;
    
    if ( setValue == null )
    {
      setValue = getOldCustAccountId();
    }
    
    setAttributeInternal(CUSTACCOUNTID, setValue);

    XxcsoUtils.debug(txn, "[END]");
  }


  /**
   * 
   * Gets the attribute value for OldCustAccountId, using the alias name OldCustAccountId
   */
  public Number getOldCustAccountId()
  {
    return (Number)getAttributeInternal(OLDCUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OldCustAccountId
   */
  public void setOldCustAccountId(Number value)
  {
    setAttributeInternal(OLDCUSTACCOUNTID, value);
  }


  /**
   * 
   * Gets the attribute value for TrgtResourceCnt, using the alias name TrgtResourceCnt
   */
  public Number getTrgtResourceCnt()
  {
    return (Number)getAttributeInternal(TRGTRESOURCECNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TrgtResourceCnt
   */
  public void setTrgtResourceCnt(Number value)
  {
    setAttributeInternal(TRGTRESOURCECNT, value);
  }

  /**
   * 
   * Gets the attribute value for NextResourceCnt, using the alias name NextResourceCnt
   */
  public Number getNextResourceCnt()
  {
    return (Number)getAttributeInternal(NEXTRESOURCECNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextResourceCnt
   */
  public void setNextResourceCnt(Number value)
  {
    setAttributeInternal(NEXTRESOURCECNT, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number custAccountId)
  {
    return new Key(new Object[] {custAccountId});
  }















}