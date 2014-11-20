/*============================================================================
* ファイル名 : XxcsoDeptMonthlyPlansVEOImpl
* 概要説明   : 拠点別月別計画ビューエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS及川領    新規作成
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
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import oracle.jdbc.OracleCallableStatement;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.sql.SQLException;
/*******************************************************************************
 * 拠点別月別計画ビューのエンティティクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoDeptMonthlyPlansVEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int BASECODE = 0;
  protected static final int TARGETYEAR = 1;
  protected static final int TARGETMONTH = 2;
  protected static final int DEPTMONTHLYPLANID = 3;
  protected static final int SALESPLANRELDIV = 4;
  protected static final int CREATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATEDBY = 7;
  protected static final int LASTUPDATEDATE = 8;
  protected static final int LASTUPDATELOGIN = 9;
  protected static final int BASENAME = 10;






  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDeptMonthlyPlansVEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoDeptMonthlyPlansVEO");
    }
    return mDefinitionObject;
  }








  /*****************************************************************************
   * エンティティのロック処理です。
   * エンティティのロック処理は登録プロシージャで行います。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * エンティティの更新処理です。
   * エンティティの作成／更新処理は登録プロシージャで行います。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    OracleCallableStatement stmt = null;

    //拠点別月別計画登録用ファンクションをcall
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append(" xxcso_019003j_pkg.set_dept_monthly_plans(");
      sql.append(" :1, :2, :3, :4);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
      // パラメータの設定
      stmt.setString(1, getBaseCode());
      stmt.setString(2, getTargetYear()+getTargetMonth());
      stmt.setNUMBER(3, getDeptMonthlyPlanId());
      stmt.setString(4, getSalesPlanRelDiv());
      
      XxcsoUtils.debug(txn, "getBaseCode:"+getBaseCode());
      XxcsoUtils.debug(txn, "getTargetYear:"+getTargetYear());
      XxcsoUtils.debug(txn, "getTargetMonth:"+getTargetMonth());
      XxcsoUtils.debug(txn, "getDeptMonthlyPlanId:"+getDeptMonthlyPlanId());
      XxcsoUtils.debug(txn, "getSalesPlanRelDiv:"+getSalesPlanRelDiv());

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
   * Gets the attribute value for TargetYear, using the alias name TargetYear
   */
  public String getTargetYear()
  {
    return (String)getAttributeInternal(TARGETYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetYear
   */
  public void setTargetYear(String value)
  {
    setAttributeInternal(TARGETYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for TargetMonth, using the alias name TargetMonth
   */
  public String getTargetMonth()
  {
    return (String)getAttributeInternal(TARGETMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TargetMonth
   */
  public void setTargetMonth(String value)
  {
    setAttributeInternal(TARGETMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for DeptMonthlyPlanId, using the alias name DeptMonthlyPlanId
   */
  public Number getDeptMonthlyPlanId()
  {
    return (Number)getAttributeInternal(DEPTMONTHLYPLANID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DeptMonthlyPlanId
   */
  public void setDeptMonthlyPlanId(Number value)
  {
    setAttributeInternal(DEPTMONTHLYPLANID, value);
  }

  /**
   * 
   * Gets the attribute value for SalesPlanRelDiv, using the alias name SalesPlanRelDiv
   */
  public String getSalesPlanRelDiv()
  {
    return (String)getAttributeInternal(SALESPLANRELDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesPlanRelDiv
   */
  public void setSalesPlanRelDiv(String value)
  {
    setAttributeInternal(SALESPLANRELDIV, value);
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
      case TARGETYEAR:
        return getTargetYear();
      case TARGETMONTH:
        return getTargetMonth();
      case DEPTMONTHLYPLANID:
        return getDeptMonthlyPlanId();
      case SALESPLANRELDIV:
        return getSalesPlanRelDiv();
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
      case BASENAME:
        return getBaseName();
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
      case TARGETYEAR:
        setTargetYear((String)value);
        return;
      case TARGETMONTH:
        setTargetMonth((String)value);
        return;
      case DEPTMONTHLYPLANID:
        setDeptMonthlyPlanId((Number)value);
        return;
      case SALESPLANRELDIV:
        setSalesPlanRelDiv((String)value);
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
      case BASENAME:
        setBaseName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }



  /**
   * 
   * Gets the attribute value for BaseName, using the alias name BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(String baseCode, String targetYear, String targetMonth, Number deptMonthlyPlanId)
  {
    return new Key(new Object[] {baseCode, targetYear, targetMonth, deptMonthlyPlanId});
  }






}