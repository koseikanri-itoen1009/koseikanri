/*============================================================================
* ファイル名 : XxcsoAcctMonthlyPlansVEOImpl
* 概要説明   : 顧客別売上計画（月別）エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-05 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;

import oracle.jbo.AttributeList;
import oracle.jbo.Key;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.AlreadyLockedException;
import oracle.jbo.RowNotFoundException;
import oracle.jbo.RowInconsistentException;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;

import java.sql.SQLException;

/*******************************************************************************
 * 顧客別売上計画（月別）のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctMonthlyPlansVEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int BASECODE = 0;
  protected static final int ACCOUNTNUMBER = 1;
  protected static final int YEARMONTH = 2;
  protected static final int PARTYID = 3;
  protected static final int VISTTARGETDIV = 4;
  protected static final int TARGETACCOUNTSALESPLANID = 5;
  protected static final int TARGETMONTHSALESPLANAMT = 6;
  protected static final int TARGETYEARMONTH = 7;
  protected static final int TARGETMONTHLASTUPDDATE = 8;
  protected static final int TARGETROUTENUMBER = 9;
  protected static final int NEXTACCOUNTSALESPLANID = 10;
  protected static final int NEXTYEARMONTH = 11;
  protected static final int NEXTMONTHSALESPLANAMT = 12;
  protected static final int NEXTMONTHLASTUPDDATE = 13;
  protected static final int NEXTROUTENUMBER = 14;
  protected static final int CREATEDBY = 15;
  protected static final int CREATIONDATE = 16;
  protected static final int LASTUPDATEDBY = 17;
  protected static final int LASTUPDATEDATE = 18;
  protected static final int LASTUPDATELOGIN = 19;
  protected static final int DISTRIBUTEFLG = 20;










  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctMonthlyPlansVEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoAcctMonthlyPlansVEO");
    }
    return mDefinitionObject;
  }














  /*****************************************************************************
   * エンティティの作成処理です。
   * 呼ばれないはずなので空振りします。
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
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

    try
    {
      OracleCallableStatement stmt = null;

      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_rsrc_sales_plans_pkg.process_lock(");
      sql.append("    in_trgt_account_sales_plan_id => :1");
      sql.append("   ,id_trgt_last_update_date      => :2");
      sql.append("   ,in_next_account_sales_plan_id => :3");
      sql.append("   ,id_next_last_update_date      => :4");
      sql.append("   ,ov_errbuf                     => :5");
      sql.append("   ,ov_retcode                    => :6");
      sql.append("   ,ov_errmsg                     => :7");
      sql.append("  );");
      sql.append("END;");

      try
      {
        stmt =
          (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

        if ( getTargetAccountSalesPlanId() != null )
        {
          stmt.setOracleObject(1, getTargetAccountSalesPlanId());
          stmt.setOracleObject(2, getTargetMonthLastUpdDate());
        }
        else
        {
          stmt.setString(1, null);
          stmt.setString(2, null);
        }

        if ( getDistributeFlg() != null &&
             "1".equals(getDistributeFlg()) &&
             getNextAccountSalesPlanId() != null )
        {
          stmt.setOracleObject(3, getNextAccountSalesPlanId());
          stmt.setOracleObject(4, getNextMonthLastUpdDate());
        }
        else
        {
          stmt.setString(3, null);
          stmt.setString(4, null);
        }
        stmt.registerOutParameter(5, OracleTypes.VARCHAR);
        stmt.registerOutParameter(6, OracleTypes.VARCHAR);
        stmt.registerOutParameter(7, OracleTypes.VARCHAR);

        stmt.execute();

        String errbuf   = stmt.getString(5);
        String retcode  = stmt.getString(6);
        String errmsg   = stmt.getString(7);

        if ( ! "0".equals(retcode) )
        {
          if ( XxcsoConstants.APP_XXCSO1_00002.equals(errmsg) )
          {
            throw XxcsoMessage.createTransactionLockError(
              XxcsoConstants.TOKEN_VALUE_ACCOUNT_NUMBER
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getAccountNumber()
                + XxcsoConstants.TOKEN_VALUE_DELIMITER2
                + XxcsoConstants.TOKEN_VALUE_BASE_CODE
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getBaseCode()
                + XxcsoConstants.TOKEN_VALUE_DELIMITER2
                + XxcsoConstants.TOKEN_VALUE_YEAR_MONTH
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getYearMonth()
            );
          }
          else if ( XxcsoConstants.APP_XXCSO1_00003.equals(errmsg) )
          {
            throw XxcsoMessage.createTransactionInconsistentError(
              XxcsoConstants.TOKEN_VALUE_ACCOUNT_NUMBER
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getAccountNumber()
                + XxcsoConstants.TOKEN_VALUE_DELIMITER2
                + XxcsoConstants.TOKEN_VALUE_BASE_CODE
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getBaseCode()
                + XxcsoConstants.TOKEN_VALUE_DELIMITER2
                + XxcsoConstants.TOKEN_VALUE_YEAR_MONTH
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getYearMonth()
            );
          }
          else
          {
            XxcsoUtils.unexpected(txn, errbuf);
            XxcsoUtils.unexpected(txn, errmsg);
            throw XxcsoMessage.createCriticalErrorMessage(
              XxcsoConstants.TOKEN_VALUE_ACCOUNT_NUMBER
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getAccountNumber()
                + XxcsoConstants.TOKEN_VALUE_DELIMITER2
                + XxcsoConstants.TOKEN_VALUE_BASE_CODE
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getBaseCode()
                + XxcsoConstants.TOKEN_VALUE_DELIMITER2
                + XxcsoConstants.TOKEN_VALUE_YEAR_MONTH
                + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                + getYearMonth()
                + XxcsoConstants.TOKEN_VALUE_REGIST
             ,errmsg
            );
          }
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
        throw XxcsoMessage.createSqlErrorMessage(
          sqle,
          XxcsoConstants.TOKEN_VALUE_ACCOUNT_NUMBER
            + XxcsoConstants.TOKEN_VALUE_DELIMITER3
            + getAccountNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoConstants.TOKEN_VALUE_BASE_CODE
            + XxcsoConstants.TOKEN_VALUE_DELIMITER3
            + getBaseCode()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoConstants.TOKEN_VALUE_YEAR_MONTH
            + XxcsoConstants.TOKEN_VALUE_DELIMITER3
            + getYearMonth()
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
        catch( SQLException sqle )
        {
          XxcsoUtils.unexpected(txn, sqle);
        }
      }
      
      setLocked(true);
    }
    catch ( AlreadyLockedException ale )
    {
    }
    catch ( RowInconsistentException rie )
    {
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_ACCOUNT_NUMBER
          + XxcsoConstants.TOKEN_VALUE_DELIMITER3
          + getAccountNumber()
          + XxcsoConstants.TOKEN_VALUE_DELIMITER2
          + XxcsoConstants.TOKEN_VALUE_BASE_CODE
          + XxcsoConstants.TOKEN_VALUE_DELIMITER3
          + getBaseCode()
          + XxcsoConstants.TOKEN_VALUE_DELIMITER2
          + XxcsoConstants.TOKEN_VALUE_YEAR_MONTH
          + XxcsoConstants.TOKEN_VALUE_DELIMITER3
          + getYearMonth()
      );      
    }
    
    XxcsoUtils.debug(txn, "[END]");

  }


  /*****************************************************************************
   * レコード作成処理です。
   * 呼ばれないはずなので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * レコード更新処理です。
   * 顧客別売上計画（月別）登録APIをCallします。
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
   * 顧客別売上計画テーブル登録更新APIをCallします。
   *****************************************************************************
   */
  private void processApiCall()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // 顧客別月別売上計画（当月）の更新確認
    if ( super.isAttributeChanged(TARGETMONTHSALESPLANAMT) )
    {
      String planAmt = getTargetMonthSalesPlanAmt();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getTargetAccountSalesPlanId();
      String planYm = getTargetYearMonth();
      updateRsrsAcctMonthly(planId, planYm, planAmt);

      if ( "1".equals(getDistributeFlg()) )
      {
        distributeRsrsAcctDaily(
          planYm
         ,getTargetRouteNumber()
         ,planAmt
        );
      }
    }
    
    // 顧客別月別売上計画（翌月以降）の更新確認
    if ( super.isAttributeChanged(NEXTMONTHSALESPLANAMT) )
    {
      String planAmt = getNextMonthSalesPlanAmt();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getNextAccountSalesPlanId();
      String planYm = getNextYearMonth();
      updateRsrsAcctMonthly(planId, planYm, planAmt);

      if ( "1".equals(getDistributeFlg()) )
      {
        distributeRsrsAcctDaily(
          planYm
         ,getNextRouteNumber()
         ,planAmt
        );
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 顧客別売上計画（月別）の登録更新APIをCallします。
   *****************************************************************************
   */
  private void updateRsrsAcctMonthly(
    Number  planId
   ,String  planYearMonth
   ,String  planAmt
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String accountNumber = getAccountNumber();
    String baseCode = getBaseCode();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.update_rsrc_acct_monthly(");
    sql.append("    in_account_sales_plan_id => :1");
    sql.append("   ,iv_base_code             => :2");
    sql.append("   ,iv_account_number        => :3");
    sql.append("   ,iv_year_month            => :4");
    sql.append("   ,iv_sales_plan_month_amt  => :5");
    sql.append("   ,iv_distribute_flg        => :6");
    sql.append("   ,ov_errbuf                => :7");
    sql.append("   ,ov_retcode               => :8");
    sql.append("   ,ov_errmsg                => :9");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setNUMBER(1, planId);
      stmt.setString(2, baseCode);
      stmt.setString(3, accountNumber);
      stmt.setString(4, planYearMonth);
      stmt.setString(5, planAmt);
      stmt.setString(6, getDistributeFlg());
      stmt.registerOutParameter(7, OracleTypes.VARCHAR);
      stmt.registerOutParameter(8, OracleTypes.VARCHAR);
      stmt.registerOutParameter(9, OracleTypes.VARCHAR);

      stmt.execute();

      String errorBuffer  = stmt.getString(7);
      String errorCode    = stmt.getString(8);
      String errorMessage = stmt.getString(9);

      if ( ! "0".equals(errorCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_UPDATE
           ,errorBuffer
          );
      }

    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_UPDATE
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
   * 顧客別売上計画（日別）按分の登録更新APIをCallします。
   *****************************************************************************
   */
  private void distributeRsrsAcctDaily(
    String  planYearMonth
   ,String  routeNumber
   ,String  planAmt
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String baseCode = getBaseCode();
    String accountNumber = getAccountNumber();
    String partyId = getPartyId();
    String vistTargetDiv = getVistTargetDiv();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.distrbt_upd_rsrc_acct_daily(");
    sql.append("    iv_year_month            => :1");
    sql.append("   ,iv_route_number          => :2");
    sql.append("   ,iv_sales_plan_month_amt  => :3");
    sql.append("   ,iv_base_code             => :4");
    sql.append("   ,iv_account_number        => :5");
    sql.append("   ,iv_party_id              => :6");
    sql.append("   ,iv_vist_targrt_div       => :7");
    sql.append("   ,ov_errbuf                => :8");
    sql.append("   ,ov_retcode               => :9");
    sql.append("   ,ov_errmsg                => :10");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, planYearMonth);
      stmt.setString(2, routeNumber);
      stmt.setString(3, planAmt);
      stmt.setString(4, baseCode);
      stmt.setString(5, accountNumber);
      stmt.setString(6, partyId);
      stmt.setString(7, vistTargetDiv);
      stmt.registerOutParameter(8, OracleTypes.VARCHAR);
      stmt.registerOutParameter(9, OracleTypes.VARCHAR);
      stmt.registerOutParameter(10, OracleTypes.VARCHAR);

      stmt.execute();

      String errorBuffer  = stmt.getString(8);
      String errorCode    = stmt.getString(9);
      String errorMessage = stmt.getString(10);

      if ( ! "0".equals(errorCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_DISTRIBUTE_SALES_PLAN
           ,errorBuffer
          );
      }

    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_UPDATE
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
   * Gets the attribute value for BaseCode, using the alias name BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
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
   * Sets <code>value</code> as the attribute value for AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for YearMonth, using the alias name YearMonth
   */
  public String getYearMonth()
  {
    return (String)getAttributeInternal(YEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for YearMonth
   */
  public void setYearMonth(String value)
  {
    setAttributeInternal(YEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for TargetAccountSalesPlanId, using the alias name TargetAccountSalesPlanId
   */
  public Number getTargetAccountSalesPlanId()
  {
    return (Number)getAttributeInternal(TARGETACCOUNTSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetAccountSalesPlanId
   */
  public void setTargetAccountSalesPlanId(Number value)
  {
    setAttributeInternal(TARGETACCOUNTSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for TargetMonthSalesPlanAmt, using the alias name TargetMonthSalesPlanAmt
   */
  public String getTargetMonthSalesPlanAmt()
  {
    return (String)getAttributeInternal(TARGETMONTHSALESPLANAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetMonthSalesPlanAmt
   */
  public void setTargetMonthSalesPlanAmt(String value)
  {
    setAttributeInternal(TARGETMONTHSALESPLANAMT, value);
  }

  /**
   * 
   * Gets the attribute value for TargetMonthLastUpdDate, using the alias name TargetMonthLastUpdDate
   */
  public Date getTargetMonthLastUpdDate()
  {
    return (Date)getAttributeInternal(TARGETMONTHLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetMonthLastUpdDate
   */
  public void setTargetMonthLastUpdDate(Date value)
  {
    setAttributeInternal(TARGETMONTHLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NextAccountSalesPlanId, using the alias name NextAccountSalesPlanId
   */
  public Number getNextAccountSalesPlanId()
  {
    return (Number)getAttributeInternal(NEXTACCOUNTSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextAccountSalesPlanId
   */
  public void setNextAccountSalesPlanId(Number value)
  {
    setAttributeInternal(NEXTACCOUNTSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for NextMonthSalesPlanAmt, using the alias name NextMonthSalesPlanAmt
   */
  public String getNextMonthSalesPlanAmt()
  {
    return (String)getAttributeInternal(NEXTMONTHSALESPLANAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextMonthSalesPlanAmt
   */
  public void setNextMonthSalesPlanAmt(String value)
  {
    setAttributeInternal(NEXTMONTHSALESPLANAMT, value);
  }

  /**
   * 
   * Gets the attribute value for NextMonthLastUpdDate, using the alias name NextMonthLastUpdDate
   */
  public Date getNextMonthLastUpdDate()
  {
    return (Date)getAttributeInternal(NEXTMONTHLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextMonthLastUpdDate
   */
  public void setNextMonthLastUpdDate(Date value)
  {
    setAttributeInternal(NEXTMONTHLASTUPDDATE, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        return getBaseCode();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case YEARMONTH:
        return getYearMonth();
      case PARTYID:
        return getPartyId();
      case VISTTARGETDIV:
        return getVistTargetDiv();
      case TARGETACCOUNTSALESPLANID:
        return getTargetAccountSalesPlanId();
      case TARGETMONTHSALESPLANAMT:
        return getTargetMonthSalesPlanAmt();
      case TARGETYEARMONTH:
        return getTargetYearMonth();
      case TARGETMONTHLASTUPDDATE:
        return getTargetMonthLastUpdDate();
      case TARGETROUTENUMBER:
        return getTargetRouteNumber();
      case NEXTACCOUNTSALESPLANID:
        return getNextAccountSalesPlanId();
      case NEXTYEARMONTH:
        return getNextYearMonth();
      case NEXTMONTHSALESPLANAMT:
        return getNextMonthSalesPlanAmt();
      case NEXTMONTHLASTUPDDATE:
        return getNextMonthLastUpdDate();
      case NEXTROUTENUMBER:
        return getNextRouteNumber();
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
      case DISTRIBUTEFLG:
        return getDistributeFlg();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        setBaseCode((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case YEARMONTH:
        setYearMonth((String)value);
        return;
      case PARTYID:
        setPartyId((String)value);
        return;
      case VISTTARGETDIV:
        setVistTargetDiv((String)value);
        return;
      case TARGETACCOUNTSALESPLANID:
        setTargetAccountSalesPlanId((Number)value);
        return;
      case TARGETMONTHSALESPLANAMT:
        setTargetMonthSalesPlanAmt((String)value);
        return;
      case TARGETYEARMONTH:
        setTargetYearMonth((String)value);
        return;
      case TARGETMONTHLASTUPDDATE:
        setTargetMonthLastUpdDate((Date)value);
        return;
      case TARGETROUTENUMBER:
        setTargetRouteNumber((String)value);
        return;
      case NEXTACCOUNTSALESPLANID:
        setNextAccountSalesPlanId((Number)value);
        return;
      case NEXTYEARMONTH:
        setNextYearMonth((String)value);
        return;
      case NEXTMONTHSALESPLANAMT:
        setNextMonthSalesPlanAmt((String)value);
        return;
      case NEXTMONTHLASTUPDDATE:
        setNextMonthLastUpdDate((Date)value);
        return;
      case NEXTROUTENUMBER:
        setNextRouteNumber((String)value);
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
      case DISTRIBUTEFLG:
        setDistributeFlg((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the attribute value for TargetYearMonth, using the alias name TargetYearMonth
   */
  public String getTargetYearMonth()
  {
    return (String)getAttributeInternal(TARGETYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetYearMonth
   */
  public void setTargetYearMonth(String value)
  {
    setAttributeInternal(TARGETYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for NextYearMonth, using the alias name NextYearMonth
   */
  public String getNextYearMonth()
  {
    return (String)getAttributeInternal(NEXTYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextYearMonth
   */
  public void setNextYearMonth(String value)
  {
    setAttributeInternal(NEXTYEARMONTH, value);
  }


  /**
   * 
   * Gets the attribute value for PartyId, using the alias name PartyId
   */
  public String getPartyId()
  {
    return (String)getAttributeInternal(PARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PartyId
   */
  public void setPartyId(String value)
  {
    setAttributeInternal(PARTYID, value);
  }



  /**
   * 
   * Gets the attribute value for TargetRouteNumber, using the alias name TargetRouteNumber
   */
  public String getTargetRouteNumber()
  {
    return (String)getAttributeInternal(TARGETROUTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetRouteNumber
   */
  public void setTargetRouteNumber(String value)
  {
    setAttributeInternal(TARGETROUTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for NextRouteNumber, using the alias name NextRouteNumber
   */
  public String getNextRouteNumber()
  {
    return (String)getAttributeInternal(NEXTROUTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NextRouteNumber
   */
  public void setNextRouteNumber(String value)
  {
    setAttributeInternal(NEXTROUTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for DistributeFlg, using the alias name DistributeFlg
   */
  public String getDistributeFlg()
  {
    return (String)getAttributeInternal(DISTRIBUTEFLG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DistributeFlg
   */
  public void setDistributeFlg(String value)
  {
    setAttributeInternal(DISTRIBUTEFLG, value);
  }


  /**
   * 
   * Gets the attribute value for VistTargetDiv, using the alias name VistTargetDiv
   */
  public String getVistTargetDiv()
  {
    return (String)getAttributeInternal(VISTTARGETDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for VistTargetDiv
   */
  public void setVistTargetDiv(String value)
  {
    setAttributeInternal(VISTTARGETDIV, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(String baseCode, String accountNumber, String yearMonth)
  {
    return new Key(new Object[] {baseCode, accountNumber, yearMonth});
  }









}