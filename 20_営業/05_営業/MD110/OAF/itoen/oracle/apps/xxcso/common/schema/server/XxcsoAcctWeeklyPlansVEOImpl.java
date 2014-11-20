/*============================================================================
* ファイル名 : XxcsoAcctWeeklyPlansVEOImpl
* 概要説明   : 顧客別売上計画（日別）エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-05 1.0  SCS小川浩    新規作成
* 2009-06-05 1.1  SCS柳平直人  [ST障害T1_1245]項目更新方法の修正
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;

import java.sql.SQLException;

import oracle.jbo.AttributeList;
import oracle.jbo.Key;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;

/*******************************************************************************
 * 顧客別売上計画（日別）のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctWeeklyPlansVEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int BASECODE = 0;
  protected static final int ACCOUNTNUMBER = 1;
  protected static final int YEARMONTH = 2;
  protected static final int WEEKINDEX = 3;
  protected static final int MONDAYCOLUMN = 4;
  protected static final int MONDAYSALESPLANID = 5;
  protected static final int MONDAYVALUE = 6;
  protected static final int TUESDAYCOLUMN = 7;
  protected static final int TUESDAYSALESPLANID = 8;
  protected static final int TUESDAYVALUE = 9;
  protected static final int WEDNESDAYCOLUMN = 10;
  protected static final int WEDNESDAYSALESPLANID = 11;
  protected static final int WEDNESDAYVALUE = 12;
  protected static final int THURSDAYCOLUMN = 13;
  protected static final int THURSDAYSALESPLANID = 14;
  protected static final int THURSDAYVALUE = 15;
  protected static final int FRIDAYCOLUMN = 16;
  protected static final int FRIDAYSALESPLANID = 17;
  protected static final int FRIDAYVALUE = 18;
  protected static final int SATURDAYCOLUMN = 19;
  protected static final int SATURDAYSALESPLANID = 20;
  protected static final int SATURDAYVALUE = 21;
  protected static final int SUNDAYCOLUMN = 22;
  protected static final int SUNDAYSALESPLANID = 23;
  protected static final int SUNDAYVALUE = 24;
  protected static final int CREATEDBY = 25;
  protected static final int CREATIONDATE = 26;
  protected static final int LASTUPDATEDBY = 27;
  protected static final int LASTUPDATEDATE = 28;
  protected static final int LASTUPDATELOGIN = 29;




  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctWeeklyPlansVEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoAcctWeeklyPlansVEO");
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

    super.setLocked(true);
    
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
   * 顧客別売上計画（日別）登録APIをCallします。
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

    // パーティIDの取得
    Number partyId = getPartyId();
    
    // 月曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(MONDAYVALUE)
//         && getMondayColumn() != null
//         && !"".equals(getMondayColumn()) )
    if ( getMondayColumn() != null && ! "".equals( getMondayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getMondayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getMondaySalesPlanId();
      String planDate = editDate(getYearMonth(), getMondayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    // 火曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(TUESDAYVALUE)
//         && getTuesdayColumn() != null
//         && !"".equals(getTuesdayColumn()) )
    if ( getTuesdayColumn() != null && ! "".equals( getTuesdayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getTuesdayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getTuesdaySalesPlanId();
      String planDate = editDate(getYearMonth(), getTuesdayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    // 水曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(WEDNESDAYVALUE)
//         && getWednesdayColumn() != null
//         && !"".equals(getWednesdayColumn()) )
    if ( getWednesdayColumn() != null && ! "".equals( getWednesdayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getWednesdayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getWednesdaySalesPlanId();
      String planDate = editDate(getYearMonth(), getWednesdayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    // 木曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(THURSDAYVALUE)
//         && getThursdayColumn() != null
//         && !"".equals(getThursdayColumn()) )
    if ( getThursdayColumn() != null && ! "".equals( getThursdayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getThursdayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getThursdaySalesPlanId();
      String planDate = editDate(getYearMonth(), getThursdayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    // 金曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(FRIDAYVALUE)
//         && getFridayColumn() != null
//         && !"".equals(getFridayColumn()) )
    if ( getFridayColumn() != null && ! "".equals( getFridayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getFridayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getFridaySalesPlanId();
      String planDate = editDate(getYearMonth(), getFridayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    // 土曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(SATURDAYVALUE)
//         && getSaturdayColumn() != null
//         && !"".equals(getSaturdayColumn()) )
    if ( getSaturdayColumn() != null && ! "".equals( getSaturdayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getSaturdayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getSaturdaySalesPlanId();
      String planDate = editDate(getYearMonth(), getSaturdayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    // 日曜日の更新確認
// 2009-06-05 [ST障害T1_1245] Mod Start
//    if ( super.isAttributeChanged(SUNDAYVALUE)
//         && getSundayColumn() != null
//         && !"".equals(getSundayColumn()) )
    if ( getSundayColumn() != null && ! "".equals( getSundayColumn() ) )
// 2009-06-05 [ST障害T1_1245] Mod End
    {
      String planAmt = getSundayValue();
      if ( planAmt != null)
      {
        planAmt = planAmt.replaceAll(",", "");
      }
      Number planId = getSundaySalesPlanId();
      String planDate = editDate(getYearMonth(), getSundayColumn());
      updateRsrsAcctDaily(planId, planDate, planAmt, partyId);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 顧客別売上計画（日別）の登録更新APIをCallします。
   *****************************************************************************
   */
  private void updateRsrsAcctDaily(
    Number  planId
   ,String  planDate
   ,String  planAmt
   ,Number  partyId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String accountNumber = getAccountNumber();
    String baseCode = getBaseCode();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.update_rsrc_acct_daily(");
    sql.append("    in_account_sales_plan_id => :1");
    sql.append("   ,iv_base_code             => :2");
    sql.append("   ,iv_account_number        => :3");
    sql.append("   ,iv_plan_date             => :4");
    sql.append("   ,iv_sales_plan_day_amt    => :5");
    sql.append("   ,in_party_id              => :6");
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
      stmt.setString(4, planDate);
      stmt.setString(5, planAmt);
      stmt.setNUMBER(6, partyId);
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
         ,XxcsoConstants.TOKEN_VALUE_ACCT_DAILY_PLAN
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
   * パーティIDを取得します。
   *****************************************************************************
   */
  private Number getPartyId()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String accountNumber = getAccountNumber();

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  :1 := xxcso_rsrc_sales_plans_pkg.get_party_id(");
    sql.append("          iv_account_number  => :2");
    sql.append("        );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    long partyId;
    
    try
    {
      XxcsoUtils.debug(txn, sql.toString());
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, accountNumber);

      stmt.execute();

      partyId  = stmt.getLong(1);

    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_ACCT_DAILY_PLAN
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

    return new Number(partyId);
  }

  /*****************************************************************************
   * 年月、日にて年月日を編集する。
   *****************************************************************************
   */
  private String editDate(String yearMonth, String day)
  {
    String day0 = "00".substring(day.length(), 2) + day;
    return (yearMonth + day0);
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
   * Gets the attribute value for WeekIndex, using the alias name WeekIndex
   */
  public Number getWeekIndex()
  {
    return (Number)getAttributeInternal(WEEKINDEX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WeekIndex
   */
  public void setWeekIndex(Number value)
  {
    setAttributeInternal(WEEKINDEX, value);
  }

  /**
   * 
   * Gets the attribute value for MondayColumn, using the alias name MondayColumn
   */
  public String getMondayColumn()
  {
    return (String)getAttributeInternal(MONDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MondayColumn
   */
  public void setMondayColumn(String value)
  {
    setAttributeInternal(MONDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for MondaySalesPlanId, using the alias name MondaySalesPlanId
   */
  public Number getMondaySalesPlanId()
  {
    return (Number)getAttributeInternal(MONDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MondaySalesPlanId
   */
  public void setMondaySalesPlanId(Number value)
  {
    setAttributeInternal(MONDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for MondayValue, using the alias name MondayValue
   */
  public String getMondayValue()
  {
    return (String)getAttributeInternal(MONDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MondayValue
   */
  public void setMondayValue(String value)
  {
    setAttributeInternal(MONDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for TuesdayColumn, using the alias name TuesdayColumn
   */
  public String getTuesdayColumn()
  {
    return (String)getAttributeInternal(TUESDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TuesdayColumn
   */
  public void setTuesdayColumn(String value)
  {
    setAttributeInternal(TUESDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for TuesdaySalesPlanId, using the alias name TuesdaySalesPlanId
   */
  public Number getTuesdaySalesPlanId()
  {
    return (Number)getAttributeInternal(TUESDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TuesdaySalesPlanId
   */
  public void setTuesdaySalesPlanId(Number value)
  {
    setAttributeInternal(TUESDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for TuesdayValue, using the alias name TuesdayValue
   */
  public String getTuesdayValue()
  {
    return (String)getAttributeInternal(TUESDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TuesdayValue
   */
  public void setTuesdayValue(String value)
  {
    setAttributeInternal(TUESDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for WednesdayColumn, using the alias name WednesdayColumn
   */
  public String getWednesdayColumn()
  {
    return (String)getAttributeInternal(WEDNESDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WednesdayColumn
   */
  public void setWednesdayColumn(String value)
  {
    setAttributeInternal(WEDNESDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for WednesdaySalesPlanId, using the alias name WednesdaySalesPlanId
   */
  public Number getWednesdaySalesPlanId()
  {
    return (Number)getAttributeInternal(WEDNESDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WednesdaySalesPlanId
   */
  public void setWednesdaySalesPlanId(Number value)
  {
    setAttributeInternal(WEDNESDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for WednesdayValue, using the alias name WednesdayValue
   */
  public String getWednesdayValue()
  {
    return (String)getAttributeInternal(WEDNESDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WednesdayValue
   */
  public void setWednesdayValue(String value)
  {
    setAttributeInternal(WEDNESDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for ThursdayColumn, using the alias name ThursdayColumn
   */
  public String getThursdayColumn()
  {
    return (String)getAttributeInternal(THURSDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThursdayColumn
   */
  public void setThursdayColumn(String value)
  {
    setAttributeInternal(THURSDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for ThursdaySalesPlanId, using the alias name ThursdaySalesPlanId
   */
  public Number getThursdaySalesPlanId()
  {
    return (Number)getAttributeInternal(THURSDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThursdaySalesPlanId
   */
  public void setThursdaySalesPlanId(Number value)
  {
    setAttributeInternal(THURSDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for ThursdayValue, using the alias name ThursdayValue
   */
  public String getThursdayValue()
  {
    return (String)getAttributeInternal(THURSDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThursdayValue
   */
  public void setThursdayValue(String value)
  {
    setAttributeInternal(THURSDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for FridayColumn, using the alias name FridayColumn
   */
  public String getFridayColumn()
  {
    return (String)getAttributeInternal(FRIDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FridayColumn
   */
  public void setFridayColumn(String value)
  {
    setAttributeInternal(FRIDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for FridaySalesPlanId, using the alias name FridaySalesPlanId
   */
  public Number getFridaySalesPlanId()
  {
    return (Number)getAttributeInternal(FRIDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FridaySalesPlanId
   */
  public void setFridaySalesPlanId(Number value)
  {
    setAttributeInternal(FRIDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for FridayValue, using the alias name FridayValue
   */
  public String getFridayValue()
  {
    return (String)getAttributeInternal(FRIDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FridayValue
   */
  public void setFridayValue(String value)
  {
    setAttributeInternal(FRIDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for SaturdayColumn, using the alias name SaturdayColumn
   */
  public String getSaturdayColumn()
  {
    return (String)getAttributeInternal(SATURDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SaturdayColumn
   */
  public void setSaturdayColumn(String value)
  {
    setAttributeInternal(SATURDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for SaturdaySalesPlanId, using the alias name SaturdaySalesPlanId
   */
  public Number getSaturdaySalesPlanId()
  {
    return (Number)getAttributeInternal(SATURDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SaturdaySalesPlanId
   */
  public void setSaturdaySalesPlanId(Number value)
  {
    setAttributeInternal(SATURDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for SaturdayValue, using the alias name SaturdayValue
   */
  public String getSaturdayValue()
  {
    return (String)getAttributeInternal(SATURDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SaturdayValue
   */
  public void setSaturdayValue(String value)
  {
    setAttributeInternal(SATURDAYVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for SundayColumn, using the alias name SundayColumn
   */
  public String getSundayColumn()
  {
    return (String)getAttributeInternal(SUNDAYCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SundayColumn
   */
  public void setSundayColumn(String value)
  {
    setAttributeInternal(SUNDAYCOLUMN, value);
  }

  /**
   * 
   * Gets the attribute value for SundaySalesPlanId, using the alias name SundaySalesPlanId
   */
  public Number getSundaySalesPlanId()
  {
    return (Number)getAttributeInternal(SUNDAYSALESPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SundaySalesPlanId
   */
  public void setSundaySalesPlanId(Number value)
  {
    setAttributeInternal(SUNDAYSALESPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for SundayValue, using the alias name SundayValue
   */
  public String getSundayValue()
  {
    return (String)getAttributeInternal(SUNDAYVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SundayValue
   */
  public void setSundayValue(String value)
  {
    setAttributeInternal(SUNDAYVALUE, value);
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
      case WEEKINDEX:
        return getWeekIndex();
      case MONDAYCOLUMN:
        return getMondayColumn();
      case MONDAYSALESPLANID:
        return getMondaySalesPlanId();
      case MONDAYVALUE:
        return getMondayValue();
      case TUESDAYCOLUMN:
        return getTuesdayColumn();
      case TUESDAYSALESPLANID:
        return getTuesdaySalesPlanId();
      case TUESDAYVALUE:
        return getTuesdayValue();
      case WEDNESDAYCOLUMN:
        return getWednesdayColumn();
      case WEDNESDAYSALESPLANID:
        return getWednesdaySalesPlanId();
      case WEDNESDAYVALUE:
        return getWednesdayValue();
      case THURSDAYCOLUMN:
        return getThursdayColumn();
      case THURSDAYSALESPLANID:
        return getThursdaySalesPlanId();
      case THURSDAYVALUE:
        return getThursdayValue();
      case FRIDAYCOLUMN:
        return getFridayColumn();
      case FRIDAYSALESPLANID:
        return getFridaySalesPlanId();
      case FRIDAYVALUE:
        return getFridayValue();
      case SATURDAYCOLUMN:
        return getSaturdayColumn();
      case SATURDAYSALESPLANID:
        return getSaturdaySalesPlanId();
      case SATURDAYVALUE:
        return getSaturdayValue();
      case SUNDAYCOLUMN:
        return getSundayColumn();
      case SUNDAYSALESPLANID:
        return getSundaySalesPlanId();
      case SUNDAYVALUE:
        return getSundayValue();
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
      case WEEKINDEX:
        setWeekIndex((Number)value);
        return;
      case MONDAYCOLUMN:
        setMondayColumn((String)value);
        return;
      case MONDAYSALESPLANID:
        setMondaySalesPlanId((Number)value);
        return;
      case MONDAYVALUE:
        setMondayValue((String)value);
        return;
      case TUESDAYCOLUMN:
        setTuesdayColumn((String)value);
        return;
      case TUESDAYSALESPLANID:
        setTuesdaySalesPlanId((Number)value);
        return;
      case TUESDAYVALUE:
        setTuesdayValue((String)value);
        return;
      case WEDNESDAYCOLUMN:
        setWednesdayColumn((String)value);
        return;
      case WEDNESDAYSALESPLANID:
        setWednesdaySalesPlanId((Number)value);
        return;
      case WEDNESDAYVALUE:
        setWednesdayValue((String)value);
        return;
      case THURSDAYCOLUMN:
        setThursdayColumn((String)value);
        return;
      case THURSDAYSALESPLANID:
        setThursdaySalesPlanId((Number)value);
        return;
      case THURSDAYVALUE:
        setThursdayValue((String)value);
        return;
      case FRIDAYCOLUMN:
        setFridayColumn((String)value);
        return;
      case FRIDAYSALESPLANID:
        setFridaySalesPlanId((Number)value);
        return;
      case FRIDAYVALUE:
        setFridayValue((String)value);
        return;
      case SATURDAYCOLUMN:
        setSaturdayColumn((String)value);
        return;
      case SATURDAYSALESPLANID:
        setSaturdaySalesPlanId((Number)value);
        return;
      case SATURDAYVALUE:
        setSaturdayValue((String)value);
        return;
      case SUNDAYCOLUMN:
        setSundayColumn((String)value);
        return;
      case SUNDAYSALESPLANID:
        setSundaySalesPlanId((Number)value);
        return;
      case SUNDAYVALUE:
        setSundayValue((String)value);
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(String baseCode, String accountNumber, String yearMonth, Number weekIndex)
  {
    return new Key(new Object[] {baseCode, accountNumber, yearMonth, weekIndex});
  }







}